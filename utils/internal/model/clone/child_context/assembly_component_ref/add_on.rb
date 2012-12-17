#for processing AssemblyComponentRefs when assembly being added is an add-on
module DTK;class ChildContext
  class AssemblyComponentRef
    class AddOn < self
      def find_component_templates_in_assembly!()
        aug_cmp_refs = get_aug_matching_component_refs()
        if aug_cmp_refs.empty?
          merge!(:matches => aug_cmp_refs)
          return
        end

        ndx_template_to_instance_nodes = self[:parent_rels].inject(Hash.new){|h,r|h.merge(r[:old_par_id] => r[:node_node_id])}
        input_for_cmp_match = Hash.new
        aug_cmp_refs.each do |cmp_ref|
          node_id = ndx_template_to_instance_nodes[cmp_ref[:node_node_id]]
          (input_for_cmp_match[node_id] ||= Array.new) << cmp_ref
        end
        
        #for each node that is not new, check if there is componenst already on target nodes that match/conflict
        cmp_ref_mh = aug_cmp_refs.first.model_handle()
        matches, conflicts = Component::ResourceMatching.find_matches_and_conflicts(cmp_ref_mh,input_for_cmp_match)
        unless conflicts.empty?
          raise ErrorUsage.new("TODO: provide conflict message")
        end
        #remove the matches
        unless matches.empty?
          matching_ids = matches.ids()
          aug_cmp_refs.reject!{|cmp| matching_ids.include?(cmp[:id])}
        end
        merge!(:matches => aug_cmp_refs)
      end

      def matching_component_refs__virtual_col()
        :component_templates
      end

    end
  end
end; end
