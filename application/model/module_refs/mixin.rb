module DTK
  class ModuleRefs
    module Mixin
      def set_component_module_version(component_module, component_version, service_version = nil)
        cmp_module_name = component_module.module_name()
        # make sure that component_module has version defined
        unless component_mb = component_module.get_module_branch_matching_version(component_version)
          defined_versions = component_module.get_module_branches().map(&:version_print_form).compact
          version_info =
            if defined_versions.empty?
              'there are no versions loaded'
            else
              "available versions: #{defined_versions.join(', ')}"
            end
          fail ErrorUsage.new("Component module (#{cmp_module_name}) does not have version (#{component_version}) defined; #{version_info}")
        end

        cmp_module_refs = get_component_module_refs(service_version)

        # check if set to this version already; if so no-op
        if cmp_module_refs.has_module_version?(cmp_module_name, component_version)
          return ret_clone_update_info(service_version)
        end

        # set in cmp_module_refs the module have specfied value and update both model and service's global refs
        cmp_module_refs.set_module_version(cmp_module_name, component_version)

        # update the component refs with the new component_template_ids
        cmp_module_refs.update_component_template_ids(component_module)

        ret_clone_update_info(service_version)
      end

      def get_component_module_refs(service_version = nil)
        branch = get_module_branch_matching_version(service_version)
        ModuleRefs.get_component_module_refs(branch)
      end
    end
  end
end
