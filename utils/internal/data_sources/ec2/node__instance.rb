module XYZ
  module DSNormalizer
    class Ec2
      class NodeInstance < Top 
        #TBD: could write 'lint checker that makes sure that target indexes correspond to schema described in models
        definitions do
          target[:image_size] = source[:flavor][:ram]
          target[:is_deployed] = true

          prefix = target[:node_interface]
          prefix[:eth0][:type] = 'ethernet' 
          prefix[:eth0][:family] = 'ipv4' 
          prefix[:eth0][:address] =  source[:private_ip_address] 

          if_exists(source[:ip_address]) do
            #TBD: may introduce (use term scope or prefix) c
            # scope[:address_access_point] do 
            #   scoped_target[:type] = "internet"
            # end
            prefix = target[:address_access_point]["internet_ipv4"]
            prefix[:type] = "internet"
            prefix[:network_address][:family] = "ipv4"
            prefix[:network_address][:address] = source[:ip_address]
            prefix[:network_partition_id] = foreign_key "/network_partition/internet"
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

