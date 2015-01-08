module DTK; class BaseModule; class UpdateModule
  class Import < self
    def import_from_puppet_forge__private(config_agent_type,impl_obj,component_includes)
      opts_parse = {
        :ret_hash_content => true,
        :include_modules  => component_includes
      }
      dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj,opts_parse)
      add_dsl_content_to_impl(impl_obj,dsl_created_info)
      set_dsl_parsed!(true)
    end
    
    def import_from_git(commit_sha,repo_idh,version,opts={})
      ret             = ModuleDSLInfo.new()
      module_branch   = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)
      
      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed
      repo  = repo_idh.create_object()
      local = ret_local(version)

      ret      = create_needed_objects_and_dsl?(repo,local,opts)
      version  = ret[:version]
      impl_obj = ret[:impl_obj]

      set_dsl_parsed!(false)
      opts_parse = {
        :dsl_created_info => ret[:dsl_created_info],
        :config_agent_type => ret[:config_agent_type]
      }.merge(opts)
      dsl_obj = parse_dsl(impl_obj,opts_parse)
      return dsl_obj if is_parsing_error?(dsl_obj)

      dsl_obj.update_model_with_ref_integrity_check(:version => version)

      component_module_refs = update_component_module_refs(module_branch,ret[:matching_module_refs])
      return component_module_refs if is_parsing_error?(component_module_refs)
      unless opts[:skip_module_ref_update]
        opts_serialize = {:create_empty_module_refs => true}.merge(Aux::hash_subset(ret,[:ambiguous,:missing]))
        if new_commit_sha = component_module_refs.serialize_and_save_to_repo?(opts_serialize)
          if opts[:ret_dsl_updated_info]
            msg = ret[:message]||"The module refs file was updated by the server"
            ret[:dsl_updated_info] = ModuleDSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
          end
        end
      end

      # parsed will be true if there are no missing or ambiguous dependencies, or flag dsl_parsed_false is not sent from the client
      dependencies = ret[:external_dependencies]||{}
      no_errors = (dependencies[:possibly_missing]||{}).empty? and (ret[:ambiguous]||{}).empty?
      if no_errors and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end

      ret
    end

    def import_from_file(commit_sha,repo_idh,version,opts={})
      ret = ModuleDSLInfo.new()
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed
      repo = repo_idh.create_object()
      local = ret_local(version)
      ret = create_needed_objects_and_dsl?(repo,local,opts)

      component_module_refs = update_component_module_refs(module_branch,ret[:matching_module_refs])
      return component_module_refs if is_parsing_error?(component_module_refs)

      opts.merge!(:ambiguous => ret[:ambiguous]) if ret[:ambiguous]
      opts.merge!(:missing => ret[:missing]) if ret[:missing]
      if new_commit_sha = component_module_refs.serialize_and_save_to_repo?(opts)
        if opts[:ret_dsl_updated_info]
          msg = "The module refs file was updated by the server"
          ret.dsl_updated_info = ModuleDSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
        end
      end
      ret
    end
   private
    def dsl_parsed?()
      @base_module.dsl_parsed?()
    end
    def get_workspace_module_branch(version)
      @base_module.get_workspace_module_branch(version)
    end
  end
end; end; end

