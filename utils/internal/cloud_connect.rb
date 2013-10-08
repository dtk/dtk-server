require 'fog'
# TODO get Fog to correct this
# monkey patch
class NilClass
  def blank?
   nil
  end
end
### end of monkey patch

module DTK
  module CloudConnect
    class Top
      def get_compute_params(opts={})
        ENV["FOG_RC"] ||= R8::Config[:ec2][:fog_credentials_path]
        ret = Fog.credentials()
        unless opts[:just_credentials]
          if region = R8::Config[:ec2][:region]
            ret = ret.merge(:region => region)
          end
        end
        ret
      end

      private
      def hash_form(x)
        x && x.attributes 
      end
    end  # => Top class

    class Route53 < Top
      def initialize(dns_domain)
        @dns_domain = dns_domain
        dns = Fog::DNS::AWS.new(get_compute_params(:just_credentials=>true))
        @r8zone = dns.zones().find { |z| z.domain.include? dns_domain}
      end
      
      def all_records()
        request_context do
          @r8zone.records
        end
      end

      def get_record(name, type=nil)
        request_context do
          5.times do
            begin
              return @r8zone.records.get(name,type)
            rescue Excon::Errors::SocketError => e
              Log.warn "Handled Excon Socket Error: #{e.message}"
            end
          end

          # if this happens it means that we need to look into more Excon::Errors::SocketError,
          # at the moment this is erratic issue which happens from time to time
          raise "Not able to get DNS record after 5 re-tries, aborting process."
        end
      end

      def destroy_record(name, type=nil)
        record = get_record(name,type)
        request_context do
          record.nil? ? false : record.destroy
        end
      end

      ##
      # name           => dns name
      # value          => URL, DNS, IP, etc.. which it links to
      # type           => DNS Record type supports A, AAA, CNAME, NS, etc.
      #
      def create_record(name, value, type = 'CNAME', ttl=300)
        request_context do
          create_hash = { :type => type, :name => name, :value => value, :ttl => ttl }
          @r8zone.records.create(create_hash)
        end
      end

      ##
      # New value for records to be linked to
      #
      def update_record(record, value)
        request_context do
          # record is changed via Fog's modify
          record.modify(:value => value)
        end
      end

      private
      LockRequest = Mutex.new
       def request_context(&block)
         #TODO: put up in heer some handling of errors such as ones that should be handled by doing a retry
         LockRequest.synchronize do
           yield
         end
       end

    end # => Route53 class

    class EC2 < Top

      WAIT_FOR_NODE = 10 # seconds

      def initialize(override_of_aws_params = nil)             
        @conn = Fog::Compute::AWS.new(override_of_aws_params||get_compute_params())
      end


      def flavor_get(id)
        hash_form(@conn.flavors.get(id))
      end

      def image_get(id)
        hash_form(@conn.images.get(id))
      end

      def servers_all()
        @conn.servers.all.map{|x|hash_form(x)}
      end

      def security_groups_all()
        @conn.security_groups.all.map{|x|hash_form(x)}
      end

      def get_instance_status(id)
        response = @conn.describe_instances('instance-id' => id)
        unless response.nil?
          status = response.body["reservationSet"].first["instancesSet"].first["instanceState"]["name"].to_sym
          launch_time = response.body["reservationSet"].first["instancesSet"].first["launchTime"]
          return { :status => status, :launch_time => launch_time, :up_time_hours => ((Time.now - launch_time)/1.hour).round }
        end
        return nil
      end

      def server_get(id)
        hash_form(wrap_servers_get(id))
      end

      def server_destroy(id)
        if server = wrap_servers_get(id)
          server.destroy
        else
          :server_does_not_exist
        end
      end

      def check_for_key_pair(name)
        unless key_pair = @conn.key_pairs.get(name)
          raise ErrorUsage.new("Not able to find IAAS keypair with name '#{name}' aborting action, please create necessery keypair")
          #key_pair = @conn.key_pairs.create(:name => name)
        end
        return key_pair
      end

      def check_for_security_group(name, description = nil)
        unless sc = @conn.security_groups.get(name)
          #sc = @conn.security_groups.create(:name => name, :description => description)
          raise ErrorUsage.new("Not able to find IAAS security group with name '#{name}' aborting action, please create necessery security group")
        end
        return sc
      end

      def server_create(options)
        hash_form(@conn.servers.create(options))
      end

      def allocate_elastic_ip
        response = @conn.allocate_address()
        if (response.status == 200)
          return response.body['publicIp']
        else
          Log.warn("Unable to allocate elastic IP from AWS, response: #{hash_form(response)}")
          return nil
        end
      end

      def release_elastic_ip(elastic_ip)
        # permently release elastic_ip
        hash_form(@conn.release_address(elastic_ip))
      end

      def disassociate_elastic_ip(elastic_ip)
        # removes elastic_ip from it's ec2 instance
        hash_form(@conn.disassociate_address(elastic_ip))
      end

      def associate_elastic_ip(instance_id, elastic_ip)
        hash_form(@conn.associate_address(instance_id, elastic_ip))
      end

      def server_start(instance_id)
        (tries=10).times do
          begin
            return hash_form(@conn.start_instances(instance_id))
          rescue Fog::Compute::AWS::Error => e
            # expected error in case node is not stopped, wait try again
            if (e.message.include? 'IncorrectInstanceState')
              Log.debug "Node with instance ID '#{instance_id}' is not yet ready, waiting #{WAIT_FOR_NODE} seconds ..."
              sleep(WAIT_FOR_NODE)
              next
            end
            raise e
          end
        end # => 10 times loop end

        raise Error, "Node (Instance ID: '#{instance_id}') not ready after #{tries*WAIT_FOR_NODE} seconds."
      end

      def server_stop(instance_id)
        hash_form(@conn.stop_instances(instance_id))
      end

      private
      def wrap_servers_get(id)
        begin
          @conn.servers.get(id)
        rescue Fog::Compute::AWS::Error => e
          Log.info("fog error: #{e.message}")
          nil
        end 
      end
    end
  end
end

