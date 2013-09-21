module DTK
  class AssemblyModule
    def self.prepare_for_edit_component_module(assembly,component_module)
      cmp_instances = get_applicable_component_instances(assembly,component_module,:raise_error_if_empty => true)
      create_component_module_version?(assembly,component_module,cmp_instances)
      module_version = ModuleVersion.create_for_assembly(assembly)
      component_module.get_workspace_branch_info(module_version)
    end

    def self.finalize_edit_component_module(assembly,component_module,module_branch)
      cmp_instances = get_applicable_component_instances(assembly,component_module)
      update_impacted_component_instances(cmp_instances,module_branch,component_module.get_project().id_handle())
    end

    def self.create_component_modules?(assembly,cmp_instances_to_prune)
      module_version = ModuleVersion.create_for_assembly(assembly)
      cmp_instances = reject_matching_component_instances(cmp_instances_to_prune,module_version)
      return if cmp_instances.empty?
      cmp_template_idhs = cmp_instances.map{|r|r.id_handle(:id => r.get_field?(:component_template_id))}
      cmp_tmpl_ndx_cmp_modules = Component::Template.get_indexed_component_modules(cmp_template_idhs)
      ndx_cmp_modules = Hash.new
      cmp_tmpl_ndx_cmp_modules.each_value do |cmp_mod|
        ndx_cmp_modules[cmp_mod[:id]] ||= cmp_mod
      end
      ndx_cmp_modules.values.map do |cmp_module|
        create_component_module_version(cmp_module,module_version)
      end
      nil
    end

   private
    def self.update_impacted_component_instances(cmp_instances,module_branch,project_idh)
      module_branch_id = module_branch[:id]
      cmp_instances_needing_update = cmp_instances.reject{|cmp|cmp[:module_branch_id] == module_branch_id}
      return if cmp_instances_needing_update.empty?
      component_types = cmp_instances_needing_update.map{|cmp|cmp[:component_type]}.uniq
      version_field = module_branch[:version]
      type_version_field_list = component_types.map{|ct|{:component_type => ct, :version_field => version_field}}
      ndx_cmp_templates = Component::Template.get_matching_type_and_version(project_idh,type_version_field_list).inject(Hash.new) do |h,r|
        h.merge(r[:component_type] => r)
      end
      rows_to_update = cmp_instances_needing_update.map do |cmp|
        if cmp_template = ndx_cmp_templates[cmp[:component_type]]
          {
            :id => cmp[:id],
            :module_branch_id => module_branch_id,
            :version => cmp_template[:version],
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

    def self.create_component_module_version?(assembly,component_module,cmp_instances)
      module_version = ModuleVersion.create_for_assembly(assembly)
      unless reject_matching_component_instances(cmp_instances,module_version).empty?
        create_component_module_version(component_module,module_version)
      end
    end

    def self.create_component_module_version(component_module,module_version)
      opts = {:base_version=>component_module.get_field?(:version),:assembly_module=>true}
      #TODO: very expensive call; will refine
      component_module.create_new_version(module_version,opts)
    end

    def self.reject_matching_component_instances(cmp_instances,module_version)
      ret = cmp_instances
      return ret if ret.empty?
      disjuncts = cmp_instances.map do |cmp|
        cmp.update_object!(:component_type,:project_project_id,:component_template_id)
        [:and,
         [:eq,:version,module_version.to_s],
         [:eq,:component_type,cmp[:component_type]],
         [:eq,:project_project_id,cmp[:project_project_id]]
        ]
      end
      sp_hash = {
        :cols => [:id,:group_id,:display_name,:component_type,:project_project_id],
        :filter => [:or] + disjuncts
      }
      matching_cmp_templates = Model.get_objs(cmp_instances.first.model_handle(),sp_hash)
      return ret if matching_cmp_templates.empty?
      ret.reject do |cmp|
        matching_cmp_templates.find do |cmp_template|
          cmp[:component_type] == cmp_template[:component_type] and
            cmp[:project_project_id] == cmp_template[:project_project_id]
        end
      end
    end
  end
end
