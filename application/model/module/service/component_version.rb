module DTK
  class ServiceModule
    module ComponentVersionMixin
      def set_component_module_version(component_module,component_version,service_version=nil)
        cmp_module_name = component_module.module_name()
        #make sure that component_module has version defined
        unless component_mb = component_module.get_module_branch_matching_version(component_version)
          raise ErrorUsage.new("Component module (#{cmp_module_name}) does not have version (#{component_version}) defined")
        end

        service_mb = get_module_branch_matching_version(service_version)
        #get the associated module_global_refs
        vconstraints = service_mb.get_module_global_refs()

        #check if set to this version already; if so no-op
        if vconstraints.include_module_version?(cmp_module_name,component_version)
          return ret_clone_update_info(service_version)
        end

=begin
TODO: probably remove; ran into case where this is blocker; e.g., when want to change version before push-clone-changes
        #make sure that the service module references the component module
        unless vconstraints.include_module?(cmp_module_name)

          #quick check is looking in module_global_refs, if no match then do more expensive
          #get_referenced_component_modules()
          unless get_referenced_component_modules().find{|r|r.module_name() == cmp_module_name}
            raise ErrorUsage.new("Service module (#{module_name()}) does not reference component module (#{cmp_module_name})")
          end        
        end
=end

        #set in vconstraints the module have specfied value and update both model and service's global refs
        vconstraints.set_module_version(cmp_module_name,component_version)
        vconstraints.save!()

        #update the component refs with the new compponent_templaet_ids
        update_component_template_ids(component_module)

        ret_clone_update_info(service_version)
      end

     private
      def update_component_template_ids(component_module)
        #first get filter so can call get_augmented_component_refs
        assembly_templates = component_module.get_associated_assembly_templates()
        return if assembly_templates.empty?
        filter = [:oneof, :id, assembly_templates.map{|r|r[:id]}]
        opts = {:filter => filter,:force_compute_template_id => true}
        aug_cmp_refs = Assembly::Template.get_augmented_component_refs(model_handle(:component),opts)
        return if aug_cmp_refs.empty?
        cmp_ref_update_rows = aug_cmp_refs.map{|r|r.hash_subset(:id,:component_template_id)}
        Model.update_from_rows(model_handle(:component_ref),cmp_ref_update_rows)
      end
    end
  end
end
