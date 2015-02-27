# This imports a single module
module DTK; class BaseModule; class UpdateModule
  class Import < self
    def initialize(base_module,version=nil)
      super(base_module)
      @module_branch = base_module.get_workspace_module_branch(version)
    end

    def self.import_puppet_forge_module(project,local_params,source_directory,cmr_update_els)
      config_agent_type = :puppet
      opts_create_mod = Opts.new(
        :config_agent_type => config_agent_type,
        :copy_files        => {:source_directory => source_directory}
      )
      module_and_branch_info = ComponentModule.create_module(project,local_params,opts_create_mod)
      module_branch_idh      = module_and_branch_info[:module_branch_idh]
      module_branch          = module_branch_idh.create_object()
      repo_id                = module_and_branch_info[:module_repo_info][:repo_id]
      repo                   = project.model_handle(:repo).createIDH(:id => repo_id).create_object()

      source   = generate_source(local_params)
      impl_obj = Implementation.create?(project,local_params,repo,config_agent_type)
      impl_obj.create_file_assets_from_dir_els()

      if external_ref = ConfigAgent.parse_external_ref?(config_agent_type, impl_obj)
        if content = external_ref[:content]
          content[:source] = source if source
          module_branch.update_external_ref(content)
        end
      else
        module_branch.update_external_ref(:source => source) if source
      end

      component_module = module_and_branch_info[:module_idh].create_object()

      module_branch.set_dsl_parsed!(false)
      include_modules = cmr_update_els.map{|r|r.component_module}

      # scaffold Puppet manifests
      opts_scaffold = Opts.create?(
        :ret_hash_content  => true,
        :include_modules?  => include_modules.empty? ? nil : include_modules
      )
      dsl_created_info = ScaffoldImplementation.create_dsl(local_params.module_name(),config_agent_type,impl_obj,opts_scaffold)

      # move top level folders/files in provider subfolder
      move_content_to_provider_subdir(repo, impl_obj)

      # add dsl file and create DTK module objects from the dsl
      UpdateModule.new(component_module).add_dsl_to_impl_and_create_objects(dsl_created_info,project,impl_obj,module_branch_idh,local_params.version)

      UpdateModuleRefs.update_component_module_refs_and_save_dsl?(module_branch,cmr_update_els,component_module)

      module_branch.set_dsl_parsed!(true)
      # need component module id to be returned to client
      component_module[:id]
    end

    def import_from_file(commit_sha,repo_idh,opts={})
      ret = UpdateModuleOutput.new()
      pull_was_needed = @module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !@module_branch.dsl_parsed?()
      return ret unless pull_was_needed or parse_needed

      repo = repo_idh.create_object()
      local = ret_local(@version)

      # TODO: provider is hardcoded to puppet until we introduce more provider types
      opts.merge!(:move_to_provider_subdir => true, :provider => 'puppet')
      create_info = create_needed_objects_and_dsl?(repo,local,opts)
      return create_info if create_info[:dsl_parse_error] && is_parsing_error?(create_info[:dsl_parse_error])

      ret           = UpdateModuleOutput.create_from_update_create_info(create_info)
      external_deps = ret.external_dependencies()

      component_module_refs = update_component_module_refs(@module_branch, create_info[:matching_module_refs])
      return component_module_refs if is_parsing_error?(component_module_refs)

      opts_save_dsl = Opts.create?(
        :create_empty_module_refs => true,
        :component_module_refs    => component_module_refs,
        :external_deps?           => external_deps
      )
      if dsl_updated_info = UpdateModuleRefs.save_dsl?(@module_branch, opts_save_dsl)
        if opts[:ret_dsl_updated_info]
          ret.merge!(:dsl_updated_info => dsl_updated_info)
        end
      end

      if !external_deps.any_errors? and !opts[:dsl_parsed_false]
        @module_branch.set_dsl_parsed!(true)
      end

      ret
    end

    def import_from_git(commit_sha,repo_idh,opts={})
      ret = UpdateModuleOutput.new()
      pull_was_needed = @module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !@module_branch.dsl_parsed?()
      return ret unless pull_was_needed or parse_needed
      repo  = repo_idh.create_object()
      local = ret_local(@version)

      opts.merge!(:move_to_provider_subdir => true)
      create_info   = create_needed_objects_and_dsl?(repo,local,opts)
      return create_info if create_info[:dsl_parse_error] && is_parsing_error?(create_info[:dsl_parse_error])

      version       = create_info[:version] # TODO: is this right or just user @version where refer to 'version'
      impl_obj      = create_info[:impl_obj]
      ret           = UpdateModuleOutput.create_from_update_create_info(create_info)
      external_deps = ret.external_dependencies()

      @module_branch.set_dsl_parsed!(false)

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
        dsl_updated_info = UpdateModuleRefs.save_dsl?(@module_branch,opts_save_dsl)
        if opts[:ret_dsl_updated_info]
          ret.merge!(:dsl_updated_info => dsl_updated_info)
        end
      end

      if !external_deps.any_errors? and !opts[:dsl_parsed_false]
        @module_branch.set_dsl_parsed!(true)
      end

      ret
    end

   private
    def dsl_parsed?()
      @base_module.dsl_parsed?()
    end

    def self.generate_source(local_params)
      return unless local_params.source_name
      "puppetforge://#{local_params.source_name}"
    end

    def self.move_content_to_provider_subdir(repo, impl_obj)
      repo.update_object!(:local_dir)
      local_dir = repo[:local_dir]
      impl_obj.move_to_provider_subdir(local_dir, "#{local_dir}/puppet")
    end
  end
end; end; end

