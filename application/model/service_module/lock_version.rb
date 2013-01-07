module DTK
  class ServiceModule
    module LockVersionMixin
      def lock_component_version__given_version(component_template_idh,version)
        #check that component belongs to service module
        component_template_id = component_template_idh.get_id()
        referenced_templates =  get_referenced_component_templates() 
        unless component_template = referenced_templates.find{|r|r[:id] == component_template_id}
          update_object!(:display_name)
          template_pp_name = component_template_idh.create_object().display_name_print_form()
          raise ErrorUsage.new("Service module (#{self[:display_name]} does not reference component template (#{template_pp_name})")
        end

        #check that version is legal
        raise_error_if_not_legal_new_version(version,component_template,referenced_templates)

      end

     private
      def raise_error_if_not_legal_new_version(version,component_template,referenced_templates)
        unless is_legal_version_format?(version)

        end
        component_type = component_template[:component_type]
        existing_versions = referenced_templates.select{|r|(r[:component_type] == component_type) and r[:version]}.map{|r|r[:version]}
        unless existing_versions.empty?
          #check taht new version is greated than any existing one 
        end
      end
    end
  end
end
