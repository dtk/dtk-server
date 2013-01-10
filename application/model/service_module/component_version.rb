module DTK
  class ServiceModule
    module ComponentVersionMixin
      def set_component_module_version(component_module,version)
        cmp_module_name = component_module.module_name()
        #make sure that component_module has version defined
        unless component_mb = component_module.get_module_branch_matching_version(version)
          raise ErrorUsage.new("Component module (#{cmp_module_name}) does not have version (#{version}) defined")
        end

        #TODO: right now no versuion associated with service module so 'nil' argument
        service_mb = get_module_branch_matching_version(nil)
        #get the associated module_version_constraints
        vconstraints = service_mb.get_module_version_constraints()

        #check if set to this version already
        if vconstraints.include_module_version?(cmp_module_name,version)
          raise ErrorUsage.new("Service module (#{module_name()}) already has component module (#{cmp_module_name}) set to version (#{version})")
        end

        #make sure that the service module references the component module
        unless vconstraints.include_module?(cmp_module_name)
          #quick check is looking in module_version_constraints, if no match then do more expensive
          #get_referenced_component_modules()
          unless get_referenced_component_modules().find{|r|r.module_name() == cmp_module_name}
            raise ErrorUsage.new("Service module (#{module_name()}) does not reference component module (#{cmp_module_name})")
          end        
        end
        #TODO: stub 
        #set in vconstraints the module have specfied value and update both model and service's global refs
        vconstraints.set_module_version(cmp_module_name,version)
        vconstraints.save!(component_mb.id_handle())
      end

    end
  end
end
