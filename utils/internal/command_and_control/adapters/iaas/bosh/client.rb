require 'addressable/uri'
require 'rest-client'

module DTK
  class CommandAndControl::IAAS::Bosh
    ##
    # HTTP Client for Bosh Director.
    # API information can be found here: https://bosh.io/docs/director-api-v1.html
    #
    class Client
      r8_nested_require('client', 'task') 
      r8_nested_require('client', 'releases') 
      include TaskMixin
      include ReleasesMixin

      ClientDefaults = {
        scheme: 'https',
        port: 25555,
        user: 'admin',
        password: 'admin'
      }

      # TODO: temp
      def director_host_address
        R8::Config[:bosh][:director][:host_address] ||
          fail(Error.new("BOSH director host address is not set"))
      end

      attr_reader :director_uuid
      def initialize(director_host = nil, options = {})
        director_host         ||= director_host_address
        @uri                  = Addressable::URI.new(ClientDefaults.merge(host: director_host).merge(options))
        @director_uuid        = director_uuid # most be called after uri set
        @default_post_headers = { headers: { 'Content-Type' => 'text/yaml' }}
      end
      
      def info
        get('/info')
      end
      
      def director_uuid
        info = info()
        unless ok_response?(info)
          fail ErrorUsage.new("Not able to connect to BOSH director at '#{@uri}'")
        end
        info['uuid']
      end

      def stemcells
        get('/stemcells')
      end

      def releases
        get('/releases')
      end

      # @returns Task object
      def deploy(manifest_yaml)
        task = post('/deployments', manifest_yaml)
        # TODO: Distingusih between tasks taht are processing from tasks that are done in message
        Log.info("Launching BOSH Task '#{task.task_id}'")
        task
      end

      def delete_deployment(deployment_name)
        delete("/deployments/#{deployment_name}")
      end

      def deployments(deployment_name = nil)
        url  = '/deployments'
        url.concat "/#{deployment_name}" if deployment_name
        get(url)
      end

      VMInfo = Struct.new(:name, :host_addresses_ipv4)

      def vm_info(node)
        node_name = node.get_field?(:display_name)
        job_name, index = InstanceId.bosh_job_and_index(node)
        vm_info_results = deployment_vms(InstanceId.new(node).deployment_name, full_format: true)
        matching_result = vm_info_results.find do |result|
          result['job_name'] == job_name and result['index'] == index
        end
        host_addresses_ipv4 = nil
        unless matching_result
          Log.error("Unexpected that did not find VM info for node '#{node_name}'")
        else
          host_addresses_ipv4 = matching_result['ips'] || []
          host_addresses_ipv4 = nil if host_addresses_ipv4.empty?
        end
        VMInfo.new(node_name, host_addresses_ipv4)
      end

      # opts can have
      #  full_format: Boolean
      def deployment_vms(deployment_name, opts = {})
        url  = "/deployments/#{deployment_name}/vms"
        unless opts[:full_format]
          get(url)
        else
          task_info = get(url, format: 'full')
          unless task_id = task_info['id']
            fail Error.new("Unexpected that no 'id' in #{task_info.inspect}")
          end
          result = poll_task_until_steady_state(task_id).result
          # make sure that it is an array, even singletun
          result.kind_of?(Array) ? result : [result]
        end
      end

      ##
      # *States can contain one of the following values:
      #  queued, processing, cancelled, cancelling, done, errored
      #
      def tasks(*states)
        params = states.empty? ? {} : { state: states.join(',') }
        get('/tasks', params)
      end

      ##
      # *Output Type can be one of these values:
      #  debug, event, result
      #
      # @returns (Hash)
      # Hash with :output element (when output type provided)
      #
      def task(id, output_type = nil)
        url = "/tasks/#{id}"
        params = {}
        if output_type
          url.concat('/output')
          params = { type: output_type }
        end

        get(url, params)
      end

      private

      def get(path, params = {})
        wrap_response do
          ::RestClient::Resource.new(full_url(path, params)).get()
        end
      end

      def post(path, body, include_headers = true)
        wrap_response do
          rez = ::RestClient::Resource.new(full_url(path), include_headers ? @default_post_headers : {})
          rez.post(body)
        end
      end

      def delete(path)
        wrap_response do
          ::RestClient::Resource.new(full_url(path)).delete()
        end
      end

      def wrap_response
       # some results cannot be parsed e.g. log outputs
        begin
          json_lines = yield
          begin
            ret = []
            json_lines.each_line do |json_string|
              ret << JSON.parse(json_string)
            end
            ret.size == 1 ? ret.first : ret
           rescue 
              { output: json_lines }
            end
        rescue ::RestClient::Exception => e
          # there are cases where 301, 302 are returned for long running processes
          # these are success responses, as explained https://bosh.io/docs/director-api-v1.html#long-running-ops
          if [301, 302].include?(e.http_code)
            location_url = e.response.headers[:location]
            bosh_task_id = location_url.match(/tasks\/(.*)$/)[1] rescue nil
            return poll_task_until_steady_state(bosh_task_id.to_i)
          end

          raise e
        end
      end

      def full_url(path, params = {})
        url = @uri.join(path).to_s
        url.concat('?').concat(generate_query_params(params)) unless params.empty?
        url
      end

      def generate_query_params(params)
        params.map { |k,v| "#{CGI.escape(k.to_s)}=#{CGI.escape(v.to_s)}" }.join('&')
      end

      def ok_response?(response)
        # TODO: there may be more checks
        response.kind_of?(Hash)
      end
    end
  end
end
