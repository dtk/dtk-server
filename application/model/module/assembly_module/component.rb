module DTK; class AssemblyModule
  class Component < self
    r8_nested_require('component','dependency')
    r8_nested_require('component','ad_hoc_link')

    def self.prepare_for_edit(assembly,component_module)
      get_applicable_component_instances(assembly,component_module,:raise_error_if_empty => true)
      create_assembly_branch?(assembly,component_module)
    end

    def self.finalize_edit(assembly,component_module,module_branch)
      cmp_instances = get_applicable_component_instances(assembly,component_module)
      update_impacted_component_instances(cmp_instances,module_branch,component_module.get_project().id_handle())
    end

    def self.create_component_dependency?(type,assembly,cmp_template,antecedent_cmp_template,opts={})
      Dependency.create_dependency?(type,assembly,cmp_template,antecedent_cmp_template,opts)
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

    def self.update_from_adhoc_links(assembly,parsed_adhoc_links)
      unless parsed_adhoc_links.size == 1
        raise Error.new("Only implented update_from_adhoc_links  size == 1")
      end
      AdHocLink.new(assembly,parsed_adhoc_links.first).update_assembly_module()
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
      #do not want to use assembly.get_component_modules() to generate component_modules because there can be modules taht do not correspond to component instances
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_id],
        :filter => [:eq,:version,module_version]
      }
      component_module_mh = assembly.model_handle(:component_module)
      Model.get_objs(assembly.model_handle(:module_branch),sp_hash).each do |r|
        component_module = component_module_mh.createIDH(:id => r[:component_id]).create_object()
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

