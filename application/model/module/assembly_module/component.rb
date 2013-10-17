module DTK; class AssemblyModule
  class Component < self
    def self.prepare_for_edit(assembly,component_module)
     get_applicable_component_instances(assembly,component_module,:raise_error_if_empty => true)
      create_assembly_branch?(assembly,component_module)
    end

    def self.finalize_edit(assembly,component_module,module_branch)
      cmp_instances = get_applicable_component_instances(assembly,component_module)
      update_impacted_component_instances(cmp_instances,module_branch,component_module.get_project().id_handle())
    end

    def self.create_component_dependency?(assembly,cmp_template,antecedent_cmp_template,opts={})
      component_module = cmp_template.get_component_module()
      ret = create_assembly_branch?(assembly,component_module)
      pp ret
      ret
    end

    def self.promote_module_updates(assembly,component_module)
      module_version = ModuleVersion.ret(assembly)
      branch = component_module.get_workspace_module_branch(module_version)
      unless ancestor_branch = branch.get_ancestor_branch?()
        raise Error.new("Cannot find ancestor branch")
      end
      branch_name = branch[:branch]
      ancestor_branch.merge_changes_and_update_model?(component_module,branch_name)
    end

   private
    def self.create_assembly_branch?(assembly,component_module)
      module_version = ModuleVersion.ret(assembly)
      unless component_module.get_workspace_module_branch(module_version)
        create_assembly_branch(component_module,module_version)
      end
      component_module.get_workspace_branch_info(module_version)
    end

    def self.create_assembly_branch(component_module,module_version)
      opts = {:base_version=>component_module.get_field?(:version),:assembly_module=>true}
      #TODO: very expensive call; will refine
      component_module.create_new_version(module_version,opts)
    end

    def self.delete_modules?(assembly)
      module_version = ModuleVersion.ret(assembly)
      assembly.get_component_modules().each do |component_module|
        component_module.delete_version?(module_version)
      end
    end

    def self.update_impacted_component_instances(cmp_instances,module_branch,project_idh)
      module_branch_id = module_branch[:id]
      cmp_instances_needing_update = cmp_instances.reject{|cmp|cmp[:module_branch_id] == module_branch_id}
      return if cmp_instances_needing_update.empty?
      component_types = cmp_instances_needing_update.map{|cmp|cmp[:component_type]}.uniq
      version_field = module_branch[:version]
      type_version_field_list = component_types.map{|ct|{:component_type => ct, :version_field => version_field}}
      ndx_cmp_templates = DTK::Component::Template.get_matching_type_and_version(project_idh,type_version_field_list).inject(Hash.new) do |h,r|
        h.merge(r[:component_type] => r)
      end
      rows_to_update = cmp_instances_needing_update.map do |cmp|
        if cmp_template = ndx_cmp_templates[cmp[:component_type]]
          {
            :id => cmp[:id],
            :module_branch_id => module_branch_id,
            :version => cmp_template[:version],
            :locked_sha => nil, #this servers to let component instance get updated as this branch is updated
            :implementation_id => cmp_template[:implementation_id],
            :ancestor_id => cmp_template[:id]
          }
        else
          Log.error("Cannot find matching component template for component instance (#{cmp.inspect}) for version (#{version_field})")
          nil
        end
      end.compact
      unless rows_to_update.empty?
        Model.update_from_rows(project_idh.createMH(:component),rows_to_update)
      end
    end

    def self.get_applicable_component_instances(assembly,component_module,opts={})
      assembly_id = assembly.id()
      ret = component_module.get_associated_component_instances().select do |cmp|
        cmp[:assembly_id] == assembly_id
      end
      if opts[:raise_error_if_empty] and ret.empty?()
        assembly_name = assembly.display_name_print_form()
        raise ErrorUsage.new("Assembly (#{assembly_name}) does not have any components belonging to module (#{component_module.get_field?(:display_name)})")
      end
      ret
    end
  end
end; end

