require  File.expand_path('mixins/monitoring_items', File.dirname(__FILE__))
module XYZ
  module DSNormalizer
    class Ec2
      class NodeImage < Top
        extend MonitoringItemsClassMixin

        definitions do
          target[:type] = 'image'
          target[:is_deployed] = true
          target[:display_name] = source[:id]
          target[:external_ref] = fn(:external_ref,source[:id])
          source_complete_for target[:monitoring_item]
          target[:monitoring_item] = fn(:default_node_monitoring_items)

          source_complete_for target[:node_interface]
          prefix = target[:node_interface]
          prefix[:eth0][:display_name] = 'eth0'
          prefix[:eth0][:type] = 'ethernet'
          prefix[:eth0][:family] = 'ipv4'

          source_complete_for target[:attribute]
          prefix = target[:attribute][:host_addresses_ipv4]
          prefix[:display_name] = 'host_addresses_ipv4'
          prefix[:is_port] = true
          prefix[:read_only] = true
          prefix[:dynamic] = true
          prefix[:data_type] = 'json'
          prefix[:semantic_type] = {':array' => 'host_address_ipv4'}
          prefix[:semantic_type_summary] = 'host_address_ipv4'
          prefix[:value_asserted] = [nil]
        end
        class << self
          def unique_keys(source)
            [:image,source[:id]]
          end

          def relative_distinguished_name(source)
            source[:id]
          end

          def external_ref(image_id)
            {'type' => 'ec2_image', 'image_id' => image_id}
          end
        end
      end
    end
  end
end
