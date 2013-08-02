module DTK; class Task
  class Template < Model
    class ConfigComponents < self
      def self.get_components(assembly,component_type=nil)
        opts = Hash.new
        if (component_type == :smoketest)
          opts.merge!(:filter_proc => lambda{|el|el[:basic_type] == "smoketest"}) 
        end
        assembly_cmps = assembly.get_component_list()
        node_centric_cmps = NodeCentric.get_component_list(assembly_cmps.map{|r|r[:node]})
        node_centric_cmps + assembly_cmps
      end
    end
   private
    class NodeCentric < self
      def self.get_component_list(nodes,opts={})
        ret = Array.new
        return ret if nodes.empty? 
        #find node_to_ng mapping
        node_filter = opts[:node_filter] || Node::Filter::NodeList.new(nodes.map{|n|n.id_handle()})
        node_to_ng = NodeGroup.get_node_groups_containing_nodes(nodes.first.model_handle(:node_group),node_filter)

        #find components associated with each node or node group      
        ndx_cmps = Hash.new
   
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:component_list],
          :filter => [:oneof, :id, ret_node_group_ids(node_to_ng) + nodes.map{|n|n[:id]}]
        }
        cmp_list = get_objs(mh.createMH(:node),sp_hash)
        return ret if cmp_list.empty?
        pp cmp_list
        ret
      end
    end
  end
end; end
