module DTK; class StateChange
  class NodeCentric < self
    def self.node_state_changes(target_idh,opts)
      ret = []
      unless added_sc_filter = ret_node_sc_filter(target_idh,opts)
        return ret
      end
      target_mh = target_idh.createMH()
      last_level = pending_create_node(target_mh,[target_idh],added_filters: [added_sc_filter])
      state_change_mh = target_mh.create_childMH(:state_change)
      while not last_level.empty?
        ret += last_level
        last_level = pending_create_node(state_change_mh,last_level.map{|obj|obj.id_handle()},added_filters: [added_sc_filter])
      end
      ##group by node id (and using fact that each wil be unique id)
      ret.map{|ch|[ch]}
    end

    def self.component_state_changes(mh,opts)
      ret = []
      # find nodes and node_to_ng mapping
      nodes,node_to_ng = get_nodes_and_node_to_ng_index(mh,opts)
      if nodes.empty?
        return ret
      end

      # find components associated with each node or node group      
      ndx_cmps = {}
   
      sp_hash = {
        cols: [:id,:display_name,:node_centric_components],
        filter: [:oneof, :id, ret_node_group_ids(node_to_ng) + nodes.map{|n|n[:id]}]
      }
      rows = get_objs(mh.createMH(:node),sp_hash)
      if rows.empty?
        return ret
      end

      rows.each do |row|
        (ndx_cmps[row[:id]] ||= []) << row[:component]
      end

      # compute state changes
      state_change_mh = mh.createMH(:state_change)
      nodes.each do |node|
        node_cmps = []
        node_id = node[:id]
        ng_ids = (node_to_ng[node_id]||{}).keys
        ([node_id] + ng_ids).each do |node_or_ng_id|
          (ndx_cmps[node_or_ng_id]||[]).each do |cmp|
            hash = {
              type: "converge_component",
              component: cmp,
              node: node,
            }
            node_cmps << create_stub(state_change_mh,hash)
          end
        end
        ret << node_cmps
      end
      ret
    end

    class << self
      private

      def ret_node_group_ids(node_to_ng)
        ng_ndx = {}
        node_to_ng.each_value{|h|h.each{|ng_id,_ng|ng_ndx[ng_id] = true}}
        ng_ndx.keys
      end
    end

    # for components finds all components associated with a given nodes or a node group it belongs to
    class AllMatching < self
      private

      # returns [nodes, node_to_ng]
      # can be overrwitten
      def self.get_nodes_and_node_to_ng_index(mh,opts)
        unless nodes = opts[:nodes]
          raise Error.new("Expecting opts[:nodes]")
        end
        node_filter = opts[:node_filter] || DTK::Node::Filter::NodeList.new(nodes.map{|n|n.id_handle()})
        node_to_ng = DTK::NodeGroup.get_node_groups_containing_nodes(mh,node_filter)
        [nodes,node_to_ng]
      end
    end

    class SingleNode < AllMatching
      private

      # returns [nodes, node_to_ng]
      # can be overrwitten
      def self.get_nodes_and_node_to_ng_index(mh,opts)
        unless node = opts[:node]
          raise Error.new("Expecting opts[:nodes]")
        end
        super(mh,nodes: [node])
      end

      def self.ret_node_sc_filter(_target_idh,opts)
        unless node = opts[:node]
          raise Error.new("Expecting opts[:node]")
        end
        [:eq, :node_id, node[:id]]
      end
    end

    class SingleNodeGroup < self
      private

      def self.ret_node_sc_filter(_target_idh,opts)
        unless node_group = opts[:node_group]
          raise Error.new("Expecting opts[:node_group]")
        end
        nodes = node_group.get_node_group_members()
        (!nodes.empty?) && [:oneof, :node_id, nodes.map{|r|r[:id]}]
      end

      # returns [nodes, node_to_ng]
      # this is for finding node - ng relation given a specific ng
      def self.get_nodes_and_node_to_ng_index(_mh,opts)
        unless node_group = opts[:node_group]
          raise Error.new("Expecting opts[:node_group]")
        end
        nodes = node_group.get_node_group_members()
        ng_id = node_group[:id]
        node_to_ng = nodes.inject({}) do |h,n|
          h.merge(n[:id] => {ng_id => true})
        end
        [nodes,node_to_ng]
      end
    end
  end
end; end
