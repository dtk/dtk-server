require File.expand_path("../ec2", File.dirname(__FILE__))
module XYZ
  module CloudProvider
    module Ec2
      class Node < Top 
        class << self
          def discover_and_update(container_id_handle,filter={})
            nodes = connection().servers_all()
            require 'pp'; pp nodes
           nodes.each do |hash|
             id_handle = find_object(container_id_handle,hash)
             if id_handle
               update_object(id_handle,hash)
             else
               create_object(container_id_handle,hash)
             end
           end
          end
         private
          def unique_key_fields
            [:id]
          end
          def name_fields
            [:id]
          end
        end
      end
    end
  end
end
