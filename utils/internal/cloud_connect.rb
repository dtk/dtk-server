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
        x ? x.attributes : nil        
      end
    end
    class EC2 < Top
      def initialize()             
        @conn = Fog::AWS::Compute.new(Fog.credentials())
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
    end
  end
end
