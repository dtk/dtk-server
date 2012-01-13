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
        @conn = Fog::Compute::AWS.new(Fog.credentials())
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
