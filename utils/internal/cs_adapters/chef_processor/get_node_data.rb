require File.expand_path('chef_server_connection', File.dirname(__FILE__))
module XYZ
  class ChefProcessor
    class NodeDataFromServer
      include ChefServerConnection
      def get_nodes_data(chef_server_uri,&_block) #TBD: chef_server_uri is stub
        initialize_chef_connection(chef_server_uri)
  get_node_list().each_key{|node_name|
    yield node_name,get_node_data(node_name),nil
    Log.info("loaded node #{node_name}")
  }
  nil
      end

      def get_node_list
        get_rest("nodes").to_hash
      end

      def get_node_data(node_name)
        r = get_rest("nodes/#{expand_node(node_name)}")
  return nil if r.nil?
    format_node_attributes(r.attribute)
      end

      private

      def format_node_attributes(attrs)
  return nil if attrs.nil?
  #TBD: stubbed to just return interfaces
  attributes = {}
        return {} unless attrs["network"]
        return {} unless interfaces = attrs["network"]["interfaces"]
  attributes[:node_interface] = {}
  interfaces.each{|int_name,int_config|
    info = int_config.reject{|k,_v| k == "addresses"}
          attributes[:node_interface][int_name.to_sym] = {info: info}
          if addrs = format_node_addresses(int_config["addresses"])
      attributes[:node_interface][int_name.to_sym][:node_interface_address] = addrs
          end
  }
  attributes
      end

      def format_node_addresses(addrs)
  return nil if addrs.nil?
  addrs.map{|addr,info|
    {addr: {address: addr, family: info["family"],
                     info: info.reject{|k,_v| k == "family"}}}
        }
      end

      # TBD: from Chef code
      def expand_node(name)
        if name =~ /./
          name = name.dup
          name.gsub!(".", "_")
        end
        name
      end
    end
  end
end
