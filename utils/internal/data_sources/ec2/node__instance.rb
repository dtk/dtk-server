require File.expand_path('mixins/monitoring_items', File.dirname(__FILE__))
module XYZ
  module DSNormalizer
    class Ec2
      class NodeInstance < Top
        extend MonitoringItemsClassMixin
        # TBD: could write 'lint checker that makes sure that target indexes correspond to schema described in models
        definitions do
          target[:type] = 'instance'
          target[:display_name] = source[:id]
          target[:external_ref] = fn(:external_ref, source[:id])
          target[:operational_status] = source[:state]
          target[:image_size] = source[:flavor][:ram]
          target[:is_deployed] = true

          source_complete_for target[:monitoring_item]
          target[:monitoring_item] = fn(:default_node_monitoring_items)

          source_complete_for target[:node_interface]
          prefix = target[:node_interface]
          prefix[:eth0][:type] = 'ethernet'
          prefix[:eth0][:family] = 'ipv4'
          prefix[:eth0][:address] =  source[:private_ip_address]
          prefix[:eth0][:network_partition_id] = foreign_key :network_partition, source[:network_partition_ref]

          source_complete_for target[:address_access_point]
          if_exists(source[:ip_address]) do
            prefix = target[:address_access_point]['internet_ipv4']
            prefix[:type] = 'internet'
            prefix[:network_address][:family] = 'ipv4'
            prefix[:network_address][:address] = source[:ip_address]
            prefix[:network_partition_id] = foreign_key :network_partition, 'internet'
          end
        end
        class << self
          def unique_keys(source)
            [:instance, source[:id]]
          end

          def relative_distinguished_name(source)
            source[:id]
          end

          def external_ref(instance_id)
            { 'type' => 'ec2_instance', 'instance_id' => instance_id }
          end

          def filter_raw_source_objects(source)
            ret = DBUpdateHash.new
            # TODO: make this data driven from model -> dependent on what is needed for virtual columns
            [:groups, :flavor].each { |k| ret[k] = source[k] if source[k] }
            ret
          end
        end
      end
    end
  end
end
