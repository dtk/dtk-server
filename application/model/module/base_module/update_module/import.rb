module DTK; class BaseModule; class UpdateModule
  class Import < self
    def initialize(base_module,version=nil)
      super(base_module)
      @module_branch = base_module.get_workspace_module_branch(version)
    end

    def import_from_puppet_forge__private(config_agent_type,impl_obj,component_includes)
      opts_scaffold = {
        :ret_hash_content => true,
        :include_modules  => component_includes
      }
      dsl_created_info = ScaffoldImplementation.create_dsl(module_name(),config_agent_type,impl_obj,opts_scaffold)
      add_dsl_content_to_impl(impl_obj,dsl_created_info)
      set_dsl_parsed!(true)
    end
    
    def import_from_git(commit_sha,repo_idh,opts={})
      ret = UpdateModuleOutput.new()
      pull_was_needed = @module_branch.pull_repo_changes?(commit_sha)
      
      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed
      repo  = repo_idh.create_object()
      local = ret_local(@version)

      create_info   = create_needed_objects_and_dsl?(repo,local,opts)
      version       = create_info[:version] # TODO: is this right or just user @version where refer to 'version'
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

      component_module_refs = update_component_module_refs(@module_branch,create_info[:matching_module_refs])
      return component_module_refs if is_parsing_error?(component_module_refs)
      
      unless opts[:skip_module_ref_update]
        opts_save_dsl = Opts.create?(
          :component_module_refs    => component_module_refs,
          :create_empty_module_refs => true,
          :external_dependencies?   => external_deps
        )
        dsl_updated_info = UpdateModuleRefs.save_dsl?(module_branch,opts_save_dsl)
        if opts[:ret_dsl_updated_info]
          ret.merge!(:dsl_updated_info => dsl_updated_info)
        end
      end

      if !external_deps.any_errors? and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end

      ret
    end

    # TODO: check why dont set_dsl_parsed!
    def import_from_file(commit_sha,repo_idh,opts={})
      ret = UpdateModuleOutput.new()
      pull_was_needed = @module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed

      repo = repo_idh.create_object()
      local = ret_local(@version)

      create_info   = create_needed_objects_and_dsl?(repo,local,opts)
      ret           = UpdateModuleOutput.create_from_update_create_info(create_info)
      external_deps = ret.external_dependencies()

      component_module_refs = update_component_module_refs(@module_branch,create_info[:matching_module_refs])
      return component_module_refs if is_parsing_error?(component_module_refs)

      opts_save_dsl = Opts.create?(
        :create_empty_module_refs => true,
        :component_module_refs    => component_module_refs,
        :external_deps?           => external_deps
      )
      if dsl_updated_info = UpdateModuleRefs.save_dsl?(@module_branch,opts_save_dsl)
        if opts[:ret_dsl_updated_info]
          opts[:ret_dsl_updated_info] = dsl_updated_info
        end
      end

      if !external_deps.any_errors? and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end

      ret
    end

   private
    def dsl_parsed?()
      @base_module.dsl_parsed?()
    end
  end
end; end; end

