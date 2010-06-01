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
          #TBD below is effectively dsl; may make more declarative using data integration dsl
          def normalize(v)
            node_addr = v[:private_ip_address] ?
            {:family => "ipv4", :address => v[:private_ip_address]} : nil
            node_interface = {:node_interface => {"eth0" => {"type" => "ethernet"}.merge(node_addr ? {:address => node_addr} : {})}}
            addr_aps = Local.addr_access_point(v[:ip_address],"ipv4","internet","internet")
            addr_aps.merge!(Local.addr_access_point(v[:dns_name],"dns","internet","internet"))
            ret = node_interface.merge(addr_aps.empty? ? {} : {:address_access_point => addr_aps})
            #TBD: including local ip and dns plus and hookup to security groups 
          end
          module Local
            def self.addr_access_point(addr,family,type,network_partition)
              if addr 
                attrs = {:type => type,:network_address => {:family => family, :address => addr}}
                attrs.merge!({Object.assoc_key(:network_partition_id) => "/network_partition/#{network_partition}"}) if network_partition
                {"#{type}_#{family}" => attrs}
              else
                {}
              end
            end
          end

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
