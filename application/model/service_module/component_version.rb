module DTK
  class ServiceModule
    module ComponentVersionMixin
      def set_component_module_version(component_module,version)
        cmp_module_name = component_module.module_name()
        #make sure that component_module has version defined
        unless module_branch = component_module.get_module_branch_matching_version(version)
          update_object!(:display_name)
          raise ErrorUsage.new("Service module (Component module (#{cmp_module_name}) does not have version (#{version}) defined")
        end

        #get the associated module_version_constraints
        
        #check if set to this version already

        #make sure that the service module references the component module
        #quick check is looking in module_version_constraints, if no match then do more expensive
        #get_referenced_component_modules()
=begin
        matching_cmp_modules = get_referenced_component_modules().select do |r|
          r.module_name() == cmp_module_name
        end


        component_template = component_template_idh.create_object().update_object!(:id,:group_id,:display_name,:component_type,:version)
        version_field = ModuleBranch.version_field(version)
        #check that component type is referenced by service module
        component_type = component_template[:component_type]
        referenced_templates = get_referenced_component_templates() 
        matching_templates = get_referenced_component_templates().select do |r|
          r[:component_type] == component_type
        end
        error = 
          if matching_templates.empty?
            :not_referenced
          elsif matching_templates.size == 1 and matching_templates.first[:version] == version_field
            :version_set_already
          end
        if error 

           when :version_set_already
            raise ErrorUsage.new("Service module (#{self[:display_name]}) already has component template (#{template_pp_name}) set to version (#{version})")
          end        
        end
        #TODO: stub 
=end
      end

    end
  end
end
