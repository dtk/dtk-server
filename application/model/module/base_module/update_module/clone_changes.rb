module DTK; class BaseModule; class UpdateModule
  class CloneChanges < self
    def update_from_clone_changes(commit_sha,diffs_summary,module_branch,version,opts={})
      ret = ModuleDSLInfo.new()
      opts.merge!(:ret_dsl_updated_info => Hash.new)
      dsl_created_info = ModuleDSLInfo::CreatedInfo.new()
      module_namespace = module_namespace()
      impl_obj = module_branch.get_implementation()
      local = ret_local(version)
      project = local.project
      opts.merge!(:project => project)
      # TODO: make more robust to handle situation where diffs dont cover all changes; think can detect by looking at shas
      impl_obj.modify_file_assets(diffs_summary)
      
      if version.kind_of?(ModuleVersion::AssemblyModule)
        if meta_file_changed = diffs_summary.meta_file_changed?()
          parse_dsl_and_update_model(impl_obj,module_branch.id_handle(),version,opts)
        end
        assembly = version.get_assembly(@base_module.model_handle(:component))
        opts_finalize = (meta_file_changed ? {:meta_file_changed => true} : {})
        AssemblyModule::Component.finalize_edit(assembly,@base_module,module_branch,opts_finalize)
      elsif ModuleDSL.contains_dsl_file?(impl_obj)
        if opts[:force_parse] or diffs_summary.meta_file_changed?() or (module_branch.dsl_parsed?() == false)
          if e = parse_dsl_and_update_model_with_err_trap(impl_obj,module_branch.id_handle(),version,opts)
            ret.dsl_parse_error = e
          end
        end
      else
        config_agent_type = config_agent_type_default()
        dsl_created_info = ScaffoldImplementation.create_dsl(module_name(),config_agent_type,impl_obj)
      end
      
      dsl_updated_info = opts[:ret_dsl_updated_info]
      unless dsl_updated_info.empty?
        ret.dsl_updated_info = dsl_updated_info
      end
      
      ret.set_external_dependencies?(opts[:external_dependencies])
      ret.dsl_created_info = dsl_created_info
      ret
    end

  private
   def parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts={})
     @base_module.parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts)
   end
 end 
end; end; end
