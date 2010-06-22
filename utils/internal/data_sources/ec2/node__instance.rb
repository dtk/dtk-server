module XYZ
  module DSNormalizer
    class Ec2
      class NodeInstance < Top 
        #TBD: could write 'lint checker that makes sure that target indexes correspond to schema described in models
        definitions do
          target[:type] = "instance"
          target[:image_size] = source[:flavor][:ram]
          target[:is_deployed] = true

          source_complete_for target[:node_interface]          
          prefix = target[:node_interface]
          prefix[:eth0][:type] = 'ethernet' 
          prefix[:eth0][:family] = 'ipv4' 
          prefix[:eth0][:address] =  source[:private_ip_address] 

          source_complete_for target[:address_access_point]
          if_exists(source[:ip_address]) do
            prefix = target[:address_access_point]["internet_ipv4"]
            prefix[:type] = "internet"
            prefix[:network_address][:family] = "ipv4"
            prefix[:network_address][:address] = source[:ip_address]
            prefix[:network_partition_id] = foreign_key :network_partition, "internet"
          end
        end
        class << self
          #TB: may put both these in form above
          #target[:ds_key] = fn(:unique_keys,[:instance,v[:id]]) or
          #target[:ds_key] = unique_keys[:instance,v[:id]]
          def unique_keys(source_hash)
            [:instance,source_hash[:id]]
          end

          def relative_distinguished_name(source_hash)
            source_hash[:id]
          end
        end
      end
    end
  end
end

