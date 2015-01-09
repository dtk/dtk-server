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
      ret             = UpdateModuleOutput.new()
      module_branch   = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)
      
      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed
      repo  = repo_idh.create_object()
      local = ret_local(version)

      create_info   = create_needed_objects_and_dsl?(repo,local,opts)
      version       = create_info[:version]
      impl_obj      = create_info[:impl_obj]
      ret           = UpdateModuleOutput.create_from_update_create_info(create_info)
      external_deps = ret.external_dependencies()

      set_dsl_parsed!(false)

      opts_parse = {:config_agent_type => create_info[:config_agent_type]}.merge(opts)
      if dsl_created_info = ret.dsl_created_info?
        opts_parse.merge!(:dsl_created_info  => dsl_created_info)
      end
      dsl_obj = parse_dsl(impl_obj,opts_parse)
      return dsl_obj if is_parsing_error?(dsl_obj)

      dsl_obj.update_model_with_ref_integrity_check(:version => version)

      component_module_refs = update_component_module_refs(module_branch,create_info[:matching_module_refs])
      return component_module_refs if is_parsing_error?(component_module_refs)
      
      unless opts[:skip_module_ref_update]
        opts_serialize = Aux::hash_subset(opts,[:ret_dsl_updated_info]).merge(:create_empty_module_refs => true)
        serialize_module_refs_and_save_to_repo?(ret,component_module_refs,external_deps,opts_serialize)
      end

      if !external_deps.any_errors? and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end

      ret
    end

    # TODO: check why dont set_dsl_parsed!
    def import_from_file(commit_sha,repo_idh,version,opts={})
      ret = UpdateModuleOutput.new()
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed

      repo = repo_idh.create_object()
      local = ret_local(version)

      create_info   = create_needed_objects_and_dsl?(repo,local,opts)
      ret           = UpdateModuleOutput.create_from_update_create_info(create_info)
      external_deps = ret.external_dependencies()

      component_module_refs = update_component_module_refs(module_branch,create_info[:matching_module_refs])
      return component_module_refs if is_parsing_error?(component_module_refs)

      opts_serialize = Aux::hash_subset(opts,[:ret_dsl_updated_info,:create_empty_module_refs])
      serialize_module_refs_and_save_to_repo?(ret,component_module_refs,external_deps,opts_serialize)

      ret
    end

   private
    # opts can have keys
    #   :create_empty_module_refs
    #   :ret_dsl_updated_info
    def serialize_module_refs_and_save_to_repo?(ret,component_module_refs,external_deps,opts={})
      serialize_info_hash = Aux::hash_subset(opts,[:create_empty_module_refs])
      if ambiguous = external_deps.ambiguous?
        serialize_info_hash.merge!(:ambiguous => ambiguous)
      end
      if possibly_missing = external_deps.possibly_missing?
        serialize_info_hash.merge!(:possibly_missing => possibly_missing)
      end
      if new_commit_sha = component_module_refs.serialize_and_save_to_repo?(serialize_info_hash)
        if opts[:ret_dsl_updated_info]
          msg = "The module refs file was updated by the server"
          ret.set_dsl_updated_info!(msg,new_commit_sha)
        end
      end
    end

    def dsl_parsed?()
      @base_module.dsl_parsed?()
    end
    def get_workspace_module_branch(version)
      @base_module.get_workspace_module_branch(version)
    end
  end
end; end; end

