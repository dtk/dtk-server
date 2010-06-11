require File.expand_path("ec2", File.dirname(__FILE__))

module XYZ
  module DSAdapter
    class Ec2
      class NodeInstance < Ec2::Top 
       private
        no_conditions do
         #TBD: allow complete_for to be top level; related to multiple conditionals poiting to same element
          complete_for target, :ds_source => :instance
          target[:eth0][:type] = 'ethernet' 
          target[:eth0][:family] = 'ipv4' 
          target[:eth0][:address] =  source[:private_ip_address] 
        end
        if_exists(source[:ip_address]) do
          #TBD: may introduce (use term scope or prefix) c
          # scope[:address_access_point] do 
          #   target[:type] = "internet"
          # end
          complete_for target[:address_access_point]

          prefix = target["internet_ipv4"][:address_access_point]
          prefix[:type] = "internet"
          prefix[:ip_address][:family] = "ipv4"
          prefix[:ip_address][:address] = source[:ip_address]
          #TBD: may allow form foreign_key[prefix] = "/network_partition/internet"
          foreign_key["internet_ipv4"][:address_access_point][:network_partition_id] = "/network_partition/internet"
        end
        require 'pp'; pp class_rules
        #TBD below is effectively dsl; may make more declarative using data integration dsl
        def normalize(v)
          node_addr = v[:private_ip_address] ? {:family => "ipv4", :address => v[:private_ip_address]} : nil
          address = node_addr ? DBUpdateHash.new({:address => node_addr}) : {}
          node_interface = {:node_interface => {"eth0" => {"type" => "ethernet"}.merge(address)}}
          addr_aps = addr_access_point(v[:ip_address],"ipv4","internet","internet")
          addr_aps.merge!(addr_access_point(v[:dns_name],"dns","internet","internet"))
          address_access_point = addr_aps.empty? ? {} : (DBUpdateHash.new({:address_access_point => addr_aps})).mark_as_complete
          node_interface.merge(address_access_point)
          #TBD: including local ip and dns plus and hookup to security groups
        end

        def addr_access_point(addr,family,type,network_partition)
          if addr 
            attrs = {:type => type,:network_address => {:family => family, :address => addr}}
            attrs.merge!({Object.assoc_key(:network_partition_id) => "/network_partition/#{network_partition}"}) if network_partition
            {"#{type}_#{family}" => attrs}
          else
            {}
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

