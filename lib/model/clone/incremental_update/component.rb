module DTK; class Clone
  module IncrementalUpdate
    # This module is responsible for incremental clone (incremental update) when component module 
    # in a service instance are updated the compoennt instance needs to be updated
    module Component
      r8_nested_require('component','dependency')
      def self.update(project_idh,components,module_branch,opts={})
        module_branch_id = module_branch[:id]
        cmps_needing_update = components.select{|cmp|component_needs_update?(cmp,module_branch_id,opts)}
        return if cmps_needing_update.empty?

        # get mapping between component instances and their templates
        # component templates indexed by component type
        instance_template_links = get_instance_template_links(project_idh,cmps_needing_update,module_branch)
        rows_to_update = cmps_needing_update.map do |cmp|
          cmp_template = instance_template_links.template(cmp)
          {
            :id => cmp[:id],
            :module_branch_id => module_branch_id,
            :version => cmp_template[:version],
            :locked_sha => nil, #this serves to let component instance get updated as this branch is updated
            :implementation_id => cmp_template[:implementation_id],
            :ancestor_id => cmp_template[:id],
            :external_ref => cmp_template[:external_ref]
            
          }
        end
        Model.update_from_rows(project_idh.createMH(:component),rows_to_update)
#        Dependency.update?(instance_template_links)
      end

     private

      def self.component_needs_update?(cmp,module_branch_id,opts={})
        opts[:meta_file_changed] or
        (cmp.get_field?(:module_branch_id) != module_branch_id) or #TODO: check how this can happen
        has_locked_sha?(cmp)
      end
      
      def self.has_locked_sha?(cmp)
        (cmp.has_key?(:locked_sha) and !cmp[:locked_sha].nil?) or 
         # added protection in case :locked_sha not in ruby object
         !cmp.get_field?(:locked_sha).nil?
      end

      def self.get_instance_template_links(project_idh,cmps,module_branch)
        ret = InstanceTemplateLinks.new()
        component_types = cmps.map{|cmp|cmp.get_field?(:component_type)}.uniq
        version_field = module_branch.get_field?(:version)
        match_el_array = component_types.map do |ct|
          DTK::Component::Template::MatchElement.new(
           :component_type => ct,
            :version_field => version_field
          )
        end
        ndx_cmp_type_template = DTK::Component::Template.get_matching_elements(project_idh,match_el_array).inject(Hash.new) do |h,r|
          h.merge(r[:component_type] => r)
        end
        cmps.each do |cmp|
          if template = ndx_cmp_type_template[cmp[:component_type]] # this should be non null; "if" just for protection
            ret.add(cmp,template)
          end
        end
        ret
      end

    end
  end
end; end
