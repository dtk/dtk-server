module DTK; class Clone
  class ChildContext
    class AssemblyNodeAttribute < self
      private

      def parent_rels
        # add to parent relationship, which is between new node and node template, relationship between new node and node (stub)
        ret_from_node_template = self[:parent_rels]
        ndx_nt_to_node = self[:parent_objs_info].inject({}) do |h, r|
          h.merge(r[:node_template_id] => r[:ancestor_id])
        end
        ret_from_node = self[:parent_objs_info].map do |r|
          { node_node_id: r[:id], old_par_id: r[:ancestor_id] }
        end
        ret_from_node_template + ret_from_node
      end
    end
  end
end; end
