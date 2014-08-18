module DTK
  class LinkDefContext
    class NodeGroupMember < self
      def self.create_node_member_contexts(link,node_mappings,cmp_mappings)
        ret = Hash.new
        ng_members_x = node_mappings.node_group_members()
        unless ng_members_x.size == 1
          raise Error.new("Only one of local or remote should be node group")
        end
        ng_members = ng_members_x.first
        # no op if there is side with cardinality == 0
        if ng_members[:nodes].size == 0
          return ret
        end
        create_node_member_contexts_aux(link,ng_members,cmp_mappings)
      end

      def self.get_node_member_components(node_ids,ng_component)
        cols = ng_component.keys
        cols << :node_node_id unless cols.include?(:node_node_id)
        sp_hash = {
          :cols => cols,
          :filter => [:and, [:oneof, :node_node_id, node_ids], [:eq, :ng_component_id, ng_component[:id]]]
        }
        cmp_mh = ng_component.model_handle
        Model.get_objs(cmp_mh,sp_hash)
      end

      private
      # returns hash where each key is a node member node id and each eleemnt is LinkDefContext relevant to linking node member to other end node
      def self.create_node_member_contexts_aux(link,ng_members,cmp_mappings)
        node_cmp_part = {:component=> cmp_mappings[ng_members[:endpoint] == :local ? :remote : :local] }
        node_ids = ng_members[:nodes].map{|n|n[:id]}
        ng_member_cmps = get_node_member_components(node_ids,cmp_mappings[ng_members[:endpoint]])
        ng_member_cmps.inject({}) do |ret,ng_member_cmp|
          link_defs_info = [node_cmp_part, {:component=>ng_member_cmp}]
          link_def_context = new(link,link_defs_info)
          ret.merge(ng_member_cmp[:node_node_id] => link_def_context)
        end
      end
    end
  end
end
