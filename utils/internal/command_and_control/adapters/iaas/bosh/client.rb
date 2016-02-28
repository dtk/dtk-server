require 'addressable/uri'
require 'rest-client'

module DTK
  class CommandAndControlAdapter::Bosh
    ##
    # HTTP Client for Bosh Director.
    # API information can be found here: https://bosh.io/docs/director-api-v1.html
    #
    class Client

      def initialize(options = {})
        @uri = Addressable::URI.new({
          scheme: 'https',
          host: R8::Config[:bosh][:host],
          port: 25555,
          user: R8::Config[:bosh][:username],
          password: R8::Config[:bosh][:password],
        }.merge!(options))

        @default_post_headers = { headers: { 'Content-Type' => 'text/yaml' }}
      end

      def info
        get('/info')
      end

      def stemcells
        get('/stemcells')
      end

      def releases
        get('/releases')
      end

      def deploy(manifest_yaml)
        post('/deployments', manifest_yaml)
      end

      def delete_deployment(deployment_name)
        delete("/deployments/#{deployment_name}")
      end

      def deployments(deployment_name = nil)
        url  = '/deployments'
        url.concat "/#{deployment_name}" if deployment_name
        get(url)
      end

      def deployment_vms(deployment_name, full_format = false)
        url  = "/deployments/#{deployment_name}/vms"
        options = full_format ? { format: 'full' } : {}
        get(url, options)
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
      # = Return
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
        begin
          result = yield
          # some results cannot be parsed e.g. log outputs
          JSON.parse yield rescue { output: result }
        rescue ::RestClient::Exception => e
          # there are cases where 301, 302 are returned for long running processes
          # these are success responses, as explained https://bosh.io/docs/director-api-v1.html#long-running-ops
          if [301, 302].include?(e.http_code)
            return { success: true }
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

    end
  end
end
