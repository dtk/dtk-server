require File.expand_path("../ec2", File.dirname(__FILE__))
module XYZ
  module CloudProvider
    module Ec2
      class Node < Top 
        class << self
          def discover_and_update(container_id_handle,filter={})
            nodes = connection().servers_all()
            require 'pp'; pp nodes
            sync_with_discovered(container_id_handle,nodes)
          end
         private
          #below is effectively dsl
          def base_attr_fn
            lambda{|v|{:node_interface => {"eth0" => {}}}}
          end
          def unique_key_fields
            [:id]
          end
          def name_fields
            [:id]
          end
          #TBD: whether should federate might be more granular than just on a class level
          def should_federate
            false
          end
        end
      end
    end
  end
end
