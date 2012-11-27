require 'fog'
#TODO get Fog to correct this
#monkey patch
class NilClass
  def blank?
   nil
  end
end
### end of monkey patch

module XYZ
  module CloudConnect
    class Top
     private
      def hash_form(x)
        x && x.attributes 
      end
    end
    class EC2 < Top
      def initialize()             
        compute_params = Fog.credentials()
        #TODO: fix up by basing on current target's params
        if region = R8::Config[:ec2][:region]
          compute_params[:region] = region
        end
        @conn = Fog::Compute::AWS.new(compute_params)
      end

      def servers_all()
        @conn.servers.all.map{|x|hash_form(x)}
      end

      def security_groups_all()
        @conn.security_groups.all.map{|x|hash_form(x)}
      end

      def flavor_get(id)
        hash_form(@conn.flavors.get(id))
      end

      def image_get(id)
        hash_form(@conn.images.get(id))
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
        hash_form(@conn.start_instances(instance_id))
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
