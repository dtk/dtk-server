require 'fog'
# TODO get Fog to correct this
# monkey patch
class NilClass
  def blank?
   nil
  end
end
### end of monkey patch

module XYZ
  module CloudConnect
    class Top
      def get_compute_params()
        compute_params = Fog.credentials()
        
        if region = R8::Config[:ec2][:region]
          compute_params[:region] = region
        end

        return compute_params
      end

      private
      def hash_form(x)
        x && x.attributes 
      end
    end  # => Top class

    class Route53 < Top

      DNS_DOMAIN = "r8network.com"

      def initialize()
        dns = Fog::DNS::AWS.new(get_compute_params())
        @r8zone = dns.zones().find { |z| z.domain.include? DNS_DOMAIN }
      end

      def all_records()
        @r8zone.records
      end

      Lock = Mutex.new

      def get(name, type=nil)
        Lock.synchronize do
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

      def destroy(name, type=nil)
        record = get(name,type)
        return (record.nil? ? false : record.destroy)
      end

      ##
      # name           => dns name
      # value          => URL, DNS, IP, etc.. which it links to
      # type           => DNS Record type supports A, AAA, CNAME, NS, etc.
      #
      def create(name, value, type = 'CNAME', ttl=300)
        create_hash = { :type => type, :name => name, :value => value, :ttl => ttl }
        @r8zone.records.create(create_hash)
      end

      ##
      # New value for records to be linked to
      #
      def modify(name, value)
        # record is changed via Fog's modify
        get(name).modify(:value => value)
      end

      def get_dns(node)
        return "#{node[:id]}.#{DNS_DOMAIN}"
      end
    end # => Route53 class

    class EC2 < Top

      WAIT_FOR_NODE = 6 # seconds

      def initialize()             
        @conn = Fog::Compute::AWS.new(get_compute_params())
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

