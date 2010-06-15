require File.expand_path("ec2", File.dirname(__FILE__))
module XYZ
  module DSAdapter
    class Ec2
      class NodeImage < Ec2::Top 
       private
        definitions do
          source_complete_for_entire_target :ds_source => @source_obj_type if @source_obj_type
        end
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

