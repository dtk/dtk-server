module DTK; class StateChange
  class NodeCentric < self
    def self.node_state_changes(target_idh,opts)
      ret = Array.new
      unless added_sc_filter = ret_node_sc_filter(target_idh,opts)
        return ret
      end
      target_mh = target_idh.createMH()
      last_level = pending_create_node(target_mh,[target_idh],:added_filters => [added_sc_filter])
      state_change_mh = target_mh.create_childMH(:state_change)
      while not last_level.empty?
        ret += last_level
        last_level = pending_create_node(state_change_mh,last_level.map{|obj|obj.id_handle()},:added_filters => [added_sc_filter])
      end
      ##group by node id (and using fact that each wil be unique id)
      ret.map{|ch|[ch]}
    end

    #for components finds all components associated with a given nodes or a node group it belonds to
    class AllMatchingNodes < self
      #finds all node-centric components associated with the set of nodes meeting filter
      #TODO: now just using components on node groups, not node-centric components on individual nodes
      def self.component_state_changes(mh,opts)
        ret = Array.new
        #find nodes and node_to_ng mapping
        nodes,node_to_ng = get_nodes_and_node_to_ng_index(mh,opts)
        if nodes.empty?
          return ret
        end
        ndx_nodes = nodes.inject(Hash.new){|h,n|h.merge(n[:id] => n)}

        #find components associated with each node group      
        ndx_cmps_by_ng = Hash.new
   
        sp_hash = {
          :cols => [:id,:display_name,:components_for_pending_changes],
          :filter => [:oneof, :id, ret_node_group_ids(node_to_ng)]
        }
        rows = get_objs(mh.createMH(:node),sp_hash)
        if rows.empty?
          return ret
        end

        rows.each do |row|
          (ndx_cmps_by_ng[row[:id]] ||= Array.new) << row[:component]
        end

        #compute state changes
        state_change_mh = mh.createMH(:state_change)
        node_to_ng.each do |node_id,ng_info|
          node = ndx_nodes[node_id]
          node_cmps = Array.new
          ng_info.each_key do |ng_id|
            (ndx_cmps_by_ng[ng_id]||[]).each do |cmp|
              hash = {
                :type => "converge_component",
                :component => cmp,
                :node => node
              }
              node_cmps << create_stub(state_change_mh,hash)
            end
          end
          ret << node_cmps
        end
        ret
      end
      private
      #returns [nodes, node_to_ng]
      #can be overrwitten
      #this is for finding node - ng relation given a set of nodes
      def self.get_nodes_and_node_to_ng_index(mh,opts)
        unless nodes = opts[:nodes]
          raise Error.new("Expecting opts[:nodes]")
        end
        node_filter = opts[:node_filter] || DTK::Node::Filter::NodeList.new(nodes.map{|n|n.id_handle()})
        node_to_ng = DTK::NodeGroup.get_node_groups_containing_nodes(mh,node_filter)
        node_ids_to_include = node_to_ng.keys
        nodes = nodes.select{|n|node_ids_to_include.include?(n[:id])}
        [nodes,node_to_ng]
      end

      def self.ret_node_group_ids(node_to_ng)
        ng_ndx = Hash.new
        node_to_ng.each_value{|h|h.each{|ng_id,ng|ng_ndx[ng_id] = true}}
        ng_ndx.keys
      end
    end

    class Node < AllMatchingNodes
      def self.component_state_changes(mh,opts)
#TODO: change to do: super(mh,:nodes => [opts[:node]])
        ret = Array.new
        unless node = opts[:node]
          raise Error.new("Expecting opts[:node]")
        end
        sp_hash = {
          :cols => [:id,:display_name,:components_for_pending_changes],
          :filter => [:eq, :id, node[:id]]
        }
        rows = get_objs(mh.createMH(:node),sp_hash)
        if rows.empty?
          return ret
        end

        node_cmps = rows.map do |row|
          hash = {
            :type => "converge_component",
            :component => row[:component],
            :node => node
          }
          create_stub(state_change_mh,hash)
        end
        [node_cmps]
      end

     private
      def self.ret_node_sc_filter(target_idh,opts)
        unless node = opts[:node]
          raise Error.new("Expecting opts[:node]")
        end
        [:eq, :node_id, node[:id]]
      end
    end

    class SingleNodeGroup < self
     private
      def self.ret_node_sc_filter(target_idh,opts)
        unless node_group = opts[:node_group]
          raise Error.new("Expecting opts[:node_group]")
        end
        nodes = node_group.get_node_members()
        (!nodes.empty?) && [:oneof, :node_id, nodes.map{|r|r[:id]}]
      end

      #returns [nodes, node_to_ng]
      #this is for finding node - ng relation given a specific ng
      def self.get_nodes_and_node_to_ng_index(mh,opts)
        unless node_group = opts[:node_group]
          raise Error.new("Expecting opts[:node_group]")
        end
        nodes = node_group.get_node_members()
        ng_id = node_group[:id]
        node_to_ng = nodes.inject(Hash.new) do |h,n|
          h.merge(n[:id] => {ng_id => true})
        end
        [nodes,node_to_ng]
      end
    end
  end
end; end
