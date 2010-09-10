module XYZ
  class Deployment < Model
    set_relation_name(:deployment,:deployment)
    class << self
      def up()
        # no table specific columns (yet)
        one_to_many :component, :node,:assoc_node_component,:node_group, :node_group_member, :attribute_link, :network_partition, :network_gateway
      end
    
      #### actions
      def discover_nodes(dpl_id_handle,discovery_type,opts={})
  #TBD: stubbed so discovery_type is ignored and just discovering from hard-wired chef srever
        raise Error.new("Deployment given (#{dpl_id_handle}) does not exist") unless exists? dpl_id_handle
        factory_id_handle = get_factory_id_handle(dpl_id_handle,:node)
  ChefProcessor.get_nodes_data_from_server(nil) do |node_name,node_data,error|
    if error
      if opts[:task]
        opts[:task].add_error(error)
        next
            else
              raise error 
            end
          end
          #TBD: stub
          print "node_name=#{node_name}\n#{JSON.pretty_generate(node_data)}\n---------------------------------\n"
    child_id_handle = get_child_id_handle(factory_id_handle,node_name.to_sym)
    if exists? child_id_handle
       Log.info("#{child_id_handle[:uri] || "node"} exists already\n")
    else
      create_from_hash(factory_id_handle,{node_name.to_sym => node_data})
      opts[:task].add_event("added node #{node_name}") if opts[:task]
      end
  end
        raise Error if (opts[:task] ? opts[:task].has_error? : nil)
      end
    end
  end
end
