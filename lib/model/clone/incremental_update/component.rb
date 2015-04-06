module DTK; class Clone
  class IncrementalUpdate
    # This module is responsible for incremental clone (incremental update) when component module 
    # in a service instance are updated the compoennt instance needs to be updated
    class Component < self
      def initialize(project_idh,module_branch)
        @project_idh = project_idh
        @module_branch = module_branch
        @module_branch_id = @module_branch[:id]
      end
      def update?(components,opts={})
        cmps_needing_update = components.select{|cmp|component_needs_update?(cmp,opts)}
        return if cmps_needing_update.empty?
        # putting this here but not in other update functions in IncrementalUpdate because this is top level entry point
        Model.Transaction do 
          update(cmps_needing_update,opts)
        end
      end

     private
      def update(components,opts={})
        # get mapping between component instances and their templates
        # component templates indexed by component type
        links = get_instance_template_links(components)
        rows_to_update = components.map do |cmp|
          cmp_template = links.template(cmp)
          {
            :id => cmp[:id],
            :module_branch_id => @module_branch_id,
            :version => cmp_template[:version],
            :locked_sha => nil, #this serves to let component instance get updated as this branch is updated
            :implementation_id => cmp_template[:implementation_id],
            :ancestor_id => cmp_template[:id],
            :external_ref => cmp_template[:external_ref]
          }
        end
        Model.update_from_rows(@project_idh.createMH(:component),rows_to_update)
        update_children(links)
      end

      def update_children(links)
        Dependency.new(links).update?()
        IncludeModule.new(links).update?()
        Attribute.new(links).update?()
      end

      def component_needs_update?(cmp,opts={})
        opts[:meta_file_changed] or
        needs_to_be_moved_to_assembly_branch?(cmp) or
        has_locked_sha?(cmp)
      end

      def needs_to_be_moved_to_assembly_branch?(cmp)
        (cmp.get_field?(:module_branch_id) != @module_branch_id)
      end
      
      def has_locked_sha?(cmp)
        (cmp.has_key?(:locked_sha) and !cmp[:locked_sha].nil?) or 
         # added protection in case :locked_sha not in ruby object
         !cmp.get_field?(:locked_sha).nil?
      end

      def get_instance_template_links(cmps)
        ret = InstanceTemplate::Links.new()
        component_types = cmps.map{|cmp|cmp.get_field?(:component_type)}.uniq
        version_field = @module_branch.get_field?(:version)
        match_el_array = component_types.map do |ct|
          DTK::Component::Template::MatchElement.new(
           :component_type => ct,
            :version_field => version_field
          )
        end
        ndx_cmp_type_template = DTK::Component::Template.get_matching_elements(@project_idh,match_el_array).inject(Hash.new) do |h,r|
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
