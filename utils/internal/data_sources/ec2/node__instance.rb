#require File.expand_path("../../hash_object", File.dirname(__FILE__))
#require File.expand_path("../data_source_adapter", File.dirname(__FILE__))
require "/root/R8Server/application/app"
#TBD above all temp for testing
require File.expand_path("ec2", File.dirname(__FILE__))

module XYZ
  module DSAdapter
    class Ec2
      class NodeInstance < Ec2::Top 
       private
        definitions do
          source_complete_for_entire_target :ds_source => @source_obj_type if @source_obj_type

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
            #TBD: modify so that if have source_complete_for at top level do not need it in nested level
            source_complete_for target[:address_access_point]
            prefix = target[:address_access_point]["internet_ipv4"]
            prefix[:type] = "internet"
            prefix[:network_address][:family] = "ipv4"
            prefix[:network_address][:address] = source[:ip_address]
            prefix[:network_partition_id] = foreign_key "/network_partition/internet"
          end
        end

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

