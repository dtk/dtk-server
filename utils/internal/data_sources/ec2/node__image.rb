require  File.expand_path('mixins/monitoring_items', File.dirname(__FILE__))
module XYZ
  module DSNormalizer
    class Ec2
      class NodeImage < Top 
        extend MonitoringItemsClassMixin

        definitions do
          target[:type] = "image"
          target[:is_deployed] = true
          target[:display_name] = source[:id]

          source_complete_for target[:monitoring_item]
          target[:monitoring_item] = fn(:default_node_monitoring_items)
          
          source_complete_for target[:node_interface]          
          prefix = target[:node_interface]
          prefix[:eth0][:type] = 'ethernet' 
          prefix[:eth0][:family] = 'ipv4' 

        end
        class << self
          def unique_keys(source)
            [:image,source[:id]]
          end

          def relative_distinguished_name(source)
            source[:id]
          end

        end
      end
    end
  end
end

