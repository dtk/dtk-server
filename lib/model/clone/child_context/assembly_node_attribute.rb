module DTK
  class ChildContext 
    class AssemblyNodeAttribute < self
     private
      def parent_rels()
        #add to parent relationship, which is between new node and node template, relationship between new node and node (stub)
        ret_from_node_template = self[:parent_rels]
        ndx_nt_to_node = self[:parent_objs_info].inject(Hash.new) do |h,r|
          h.merge(r[:node_template_id] => r[:ancestor_id])
        end
        ret_from_node = ret_from_node_template.map do |r|
          r.merge(:old_par_id => ndx_nt_to_node[r[:old_par_id]])
        end
        ret_from_node_template + ret_from_node
      end
    end
  end
end

