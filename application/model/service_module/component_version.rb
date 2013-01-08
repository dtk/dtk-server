module DTK
  class ServiceModule
    module ComponentVersionMixin
      def set_component_version(component_template_idh,version)
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
          update_object!(:display_name)
          template_pp_name = component_template_idh.create_object().display_name_print_form()
          case error
           when :not_referenced
            raise ErrorUsage.new("Service module (#{self[:display_name]}) does not reference component template (#{template_pp_name})")
           when :version_set_already
            raise ErrorUsage.new("Service module (#{self[:display_name]}) already has component template (#{template_pp_name}) set to version (#{version})")
          end        
        end
        #TODO: stub 
      end

    end
  end
end
