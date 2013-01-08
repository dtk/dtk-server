module DTK
  class ServiceModule
    module ComponentVersionMixin
      def set_component_version(component_template_idh,version)
        #check that component belongs to service module
        component_template_id = component_template_idh.get_id()
        referenced_templates =  get_referenced_component_templates() 
        unless component_template = referenced_templates.find{|r|r[:id] == component_template_id}
          update_object!(:display_name)
          template_pp_name = component_template_idh.create_object().display_name_print_form()
          raise ErrorUsage.new("Service module (#{self[:display_name]} does not reference component template (#{template_pp_name})")
        end
        #TODO: stub 

      end

    end
  end
end
