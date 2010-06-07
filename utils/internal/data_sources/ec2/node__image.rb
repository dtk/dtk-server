require File.expand_path("ec2", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Ec2
      class NodeImage < Ec2::Top 
       private
        #TBD below is effectively dsl; may make more declarative using data integration dsl
        def unique_keys(v)
          [:image,v[:id]]
        end

        def relative_distinguished_name(v)
          v[:id]
        end
      end
    end
  end
end

