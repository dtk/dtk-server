require File.expand_path("ec2", File.dirname(__FILE__))

module XYZ
  module DSAdapter
    class Ec2
      class NodeInstance < Ec2::Top 
        #TBD: could write 'lint checker that makes sure that target indexes correspond to schema described in models
        definitions do
          source_complete_for_entire_target :ds_source => @source_obj_type 
          target[:image_size] = source[:flavor][:ram]
          target[:is_deployed] = true

          source_complete_for target[:node_interface]
          prefix = target[:node_interface]
          prefix[:eth0][:type] = 'ethernet' 
          prefix[:eth0][:family] = 'ipv4' 
          prefix[:eth0][:address] =  source[:private_ip_address] 

          source_complete_for target[:address_access_point]
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

        #TB: may put both these in form above
        #target[:ds_key] = fn(:unique_keys,[:instance,v[:id]]) or
        #target[:ds_key] = unique_keys[:instance,v[:id]]
        def unique_keys(v)
          [:instance,v[:id]]
        end

        def relative_distinguished_name(v)
          v[:id]
        end
      end
    end
  end
end

