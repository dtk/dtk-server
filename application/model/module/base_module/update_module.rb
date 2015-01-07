# TODO: trying to better isolate public methods from private ones. Want to go to solution where there is asmall mixin of the public methods
# available on BaseModule subclasses and then these call an embedded object; but for time being keeping all as mixin and 
# inserting __private members
# TODO: useful to seperate out what applies to service modules as well as component,test, etc
module DTK; class BaseModule; module UpdateModule
  r8_nested_require('update_module','external_dependencies')
  r8_nested_require('update_module','update_module_refs')
  r8_nested_require('update_module','external_refs')

  module Mixin
    include ExternalRefsMixin

    ## TODO: see if any can be moved to being private                                
    ####### public methods #########

    # called when installing from dtkn catalog
    def install__process_dsl(repo,module_branch,local,opts={})
      create_needed_objects_and_dsl?(repo,local,opts)
    end
    
    def import_from_puppet_forge(config_agent_type,impl_obj,component_includes)
      import_from_puppet_forge__private(config_agent_type,impl_obj,component_includes)
    end
    
    def import_from_git(commit_sha,repo_idh,version,opts={})
      import_from_git__private(commit_sha,repo_idh,version,opts)
    end

    def import_from_file(commit_sha,repo_idh,version,opts={})
      import_from_file__private(commit_sha,repo_idh,version,opts)
    end

    def pull_from_remote__update_from_dsl(repo, module_and_branch_info,version=nil)
      pull_from_remote__update_from_dsl__private(repo, module_and_branch_info,version)
    end

    def parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts={})
      parse_dsl_and_update_model__private(impl_obj,module_branch_idh,version,opts)
    end

    def create_new_version__type_specific(repo_for_new_branch,new_version,opts={})
      local = ret_local(new_version)
      create_needed_objects_and_dsl?(repo_for_new_branch,local,opts)
    end

    ####### end: public methods #########

    # TODO: update_model_from_clone__type_specific? is called from module/mixins from
    # update_model_from_clone_changes?, which more naturally belongs here, but cant now because then would not
    # apply to service modules. More generally need to seperate out what applies to service modules as well as component,test, etc

    # TODO: for testing
    def test_generate_dsl()
      module_branch = get_module_branch_matching_version()
      config_agent_type = :puppet
      impl_obj = module_branch.get_implementation()
      parse_impl_to_create_dsl(config_agent_type,impl_obj)
    end
    ### end: for testing

  private    
    def import_from_puppet_forge__private(config_agent_type,impl_obj,component_includes)
      opts_parse = {
        :ret_hash_content => true,
        :include_modules  => component_includes
      }
      dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj,opts_parse)
      add_dsl_content_to_impl(impl_obj,dsl_created_info)
      set_dsl_parsed!(true)
    end
    
    def import_from_git__private(commit_sha,repo_idh,version,opts={})
      ret             = DSLInfo.new()
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
      dsl_obj = klass().parse_dsl(self,impl_obj,opts_parse)
      return dsl_obj if ModuleDSL::ParsingError.is_error?(dsl_obj)

      # this will update module.module_ref table based on dependencies we found in metadata.json or Modulefile
      # when doing import-git
      dsl_obj.update_model_with_ref_integrity_check(:version => version)

      component_module_refs = UpdateModuleRefs.update_component_module_refs(module_branch,ret[:matching_module_refs],self.class)
      return component_module_refs if ModuleDSL::ParsingError.is_error?(component_module_refs)
      unless opts[:skip_module_ref_update]
        opts_serialize = Hash.new
        opts_serialize.merge!(:ambiguous => ret[:ambiguous]) if ret[:ambiguous]
        opts_serialize.merge!(:missing => ret[:missing]) if ret[:missing]
        opts_serialize.merge!(:create_empty_module_refs => true)
        # For Aldin: not high priority, but think that we should not need to pass in
        #
        # For Rich: DONE
        # I think :matching_module_refs was used for import and push if we add new includes or module_refs
        # but think we don't need it for import-git
        # opts_serialize.merge!(:matching_module_refs => ret[:matching_module_refs]) if ret[:matching_module_refs]
        if new_commit_sha = component_module_refs.serialize_and_save_to_repo?(opts_serialize)
          if opts[:ret_dsl_updated_info]
            msg = ret[:message]||"The module refs file was updated by the server"
            ret[:dsl_updated_info] = DSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
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

    def import_from_file__private(commit_sha,repo_idh,version,opts={})
      ret = DSLInfo.new()
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed
      repo = repo_idh.create_object()
      local = ret_local(version)
      ret = create_needed_objects_and_dsl?(repo,local,opts)

      component_module_refs = UpdateModuleRefs.update_component_module_refs(module_branch,ret[:matching_module_refs],self.class)
      return component_module_refs if ModuleDSL::ParsingError.is_error?(component_module_refs)

      opts.merge!(:ambiguous => ret[:ambiguous]) if ret[:ambiguous]
      opts.merge!(:missing => ret[:missing]) if ret[:missing]
      ret_cmr = ModuleRefs.get_component_module_refs(module_branch)
      if new_commit_sha = ret_cmr.serialize_and_save_to_repo?(opts)
        if opts[:ret_dsl_updated_info]
          msg = "The module refs file was updated by the server"
          ret.dsl_updated_info = DSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
        end
      end
      ret
    end

    def pull_from_remote__update_from_dsl__private(repo, module_and_branch_info,version=nil)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo)
      create_needed_objects_and_dsl?(repo,ret_local(version))
    end

    def parse_dsl_and_update_model__private(impl_obj,module_branch_idh,version,opts={})
      set_dsl_parsed!(false)
      ret, tmp_opts = {}, {}
      module_branch = module_branch_idh.create_object()
      config_agent_type = opts[:config_agent_type] || config_agent_type_default()
      dsl_obj = klass().parse_dsl(self,impl_obj,opts.merge(:config_agent_type => config_agent_type))
      return dsl_obj if ModuleDSL::ParsingError.is_error?(dsl_obj)

      if opts[:update_from_includes]
        ret = UpdateModuleRefs.new(dsl_obj,self.class).validate_includes_and_update_module_refs()
        return ret if ModuleDSL::ParsingError.is_error?(ret)
      end

      dsl_obj.update_model_with_ref_integrity_check(:version => version)
      tmp_opts.merge!(:ambiguous => ret[:ambiguous]) if ret[:ambiguous]
      unless opts[:skip_module_ref_update]
        ret_cmr = ModuleRefs.get_component_module_refs(module_branch)
        if new_commit_sha = ret_cmr.serialize_and_save_to_repo?(tmp_opts)
          if opts[:ret_dsl_updated_info]
            msg = ret[:message]||"The module refs file was updated by the server"
            opts[:ret_dsl_updated_info] = DSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
          end
        end
      end

      # parsed will be true if there are no missing or ambiguous dependencies, or flag dsl_parsed_false is not sent from the client
      dependencies = ret[:external_dependencies]||{}
      no_errors = (dependencies[:possibly_missing]||{}).empty? and (ret[:ambiguous]||{}).empty?
      if no_errors and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end
      ret unless no_errors
    end

    def ret_local(version)
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        :module_type => module_type(),
        :module_name => module_name(),
        :namespace   => module_namespace(),
        :version     => version
      )
      local_params.create_local(get_project())
    end

    def create_needed_objects_and_dsl?(repo, local, opts={})
      ret = DSLInfo.new()
      opts.merge!(:ret_dsl_updated_info => Hash.new)
      project = local.project

      config_agent_type = opts[:config_agent_type] || config_agent_type_default()
      impl_obj = Implementation.create?(project,local,repo,config_agent_type)
      impl_obj.create_file_assets_from_dir_els()

      ret_hash = {
        :name              => module_name(),
        :namespace         => module_namespace(),
        :type              => module_type(),
        :version           => local.version,
        :impl_obj          => impl_obj,
        :config_agent_type => config_agent_type
      }
      ret.merge!(ret_hash)

      module_and_branch_info = self.class.create_module_and_branch_obj?(project,repo.id_handle(),local,opts[:ancestor_branch_idh])
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      module_branch = module_branch_idh.create_object()

      # process any external refs if one of the flags :process_external_refs,:set_external_refs is true
      opts_external_refs = Aux.hash_subset(opts,[:process_external_refs,:set_external_refs])
      unless opts_external_refs.empty?
        # external_ref if non null ,will have info from the config agent related meta files such as Puppert ModuleFile 
        if external_ref = ConfigAgent.parse_external_ref?(config_agent_type,impl_obj) 
          module_branch.update_external_ref(external_ref[:content]) if external_ref[:content]
          if opts[:process_external_refs]
            external_deps = check_and_ret_external_ref_dependencies?(external_ref,project,module_branch)
            ret.merge!(external_deps.ret_hash_info())
          end
        end
      end

      dsl_created_info = DSLInfo::CreatedInfo.new()
      klass = klass()
      if klass.contains_dsl_file?(impl_obj)
        opts_parse = opts.merge(:project => project)
        if err = klass::ParsingError.trap{parse_dsl_and_update_model(impl_obj,module_branch_idh,local.version,opts_parse)}
          ret.dsl_parsed_info = err
        end
      elsif opts[:scaffold_if_no_dsl]
        opts_parse = Hash.new
        if ret[:matching_module_refs]
          opts_parse.merge!(:include_modules => ret[:matching_module_refs].map{|r|r.component_module})
        end
        dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj,opts_parse)
        if opts[:commit_dsl]
          add_dsl_content_to_impl(impl_obj,dsl_created_info)
        end
      end

      if ext_deps = opts[:external_dependencies]
        ret.merge!(:external_dependencies => ext_deps) unless ret[:external_dependencies]
      end

      dsl_updated_info = opts[:ret_dsl_updated_info]
      if dsl_updated_info && !dsl_updated_info.empty?
        ret.dsl_updated_info = dsl_updated_info
      end

      ret.merge(:module_branch_idh => module_branch_idh, :dsl_created_info => dsl_created_info)
    end

    def add_dsl_content_to_impl(impl_obj,dsl_created_info)
      impl_obj.add_file_and_push_to_repo(dsl_created_info[:path],dsl_created_info[:content])
    end

    def update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version,opts={})
      ret = DSLInfo.new()
      opts.merge!(:ret_dsl_updated_info => Hash.new)
      dsl_created_info = DSLInfo::CreatedInfo.new()
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
        assembly = version.get_assembly(model_handle(:component))
        opts_finalize = (meta_file_changed ? {:meta_file_changed => true} : {})
        AssemblyModule::Component.finalize_edit(assembly,self,module_branch,opts_finalize)
      elsif ModuleDSL.contains_dsl_file?(impl_obj)
        if opts[:force_parse] or diffs_summary.meta_file_changed?() or (get_field?(:dsl_parsed) == false)
          if e = ModuleDSL::ParsingError.trap{parse_dsl_and_update_model(impl_obj,module_branch.id_handle(),version,opts)}
            ret.dsl_parsed_info = e
          end
        end
      else
        config_agent_type = config_agent_type_default()
        dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj)
      end

      dsl_updated_info = opts[:ret_dsl_updated_info]
      unless dsl_updated_info.empty?
        ret.dsl_updated_info = dsl_updated_info
      end

      if ext_deps = opts[:external_dependencies]
        ret.merge!(:external_dependencies => ext_deps) unless ret[:external_dependencies]
      end

      ret.dsl_created_info = dsl_created_info
      ret
    end

    # Rich: DTK-1754 pass in an (optional) option that indicates scaffolding strategy
    # will build in flexibility to support a number of varaints in how Puppet as an example
    # gets mapped to a starting point dtk.model.yaml file
    # Initially we wil hace existing stargey for the top level and
    # completely commented out for the component module dependencies
    # As we progress we can identiy two pieces of info
    # 1) what signatures get parsed (e.g., only top level puppet ones) and put in dtk
    # 2) what signatures get parsed and put in commented out
    def parse_impl_to_create_dsl(config_agent_type,impl_obj,opts={})
      ret = DSLInfo::CreatedInfo.new()
      parsing_error = nil
      render_hash = nil
      begin
        impl_parse = ConfigAgent.parse_given_module_directory(config_agent_type,impl_obj)
        dsl_generator = ModuleDSL::GenerateFromImpl.create()
        # refinement_hash is version neutral form gotten from version specfic dsl_generator
        refinement_hash = dsl_generator.generate_refinement_hash(impl_parse,module_name(),impl_obj.id_handle())
        render_hash = refinement_hash.render_hash_form(opts)
       rescue ErrorUsage => e
        # parsing_error = ErrorUsage.new("Error parsing #{config_agent_type} files to generate meta data")
        parsing_error = e
       rescue => e
        Log.error_pp([:parsing_error,e,e.backtrace[0..10]])
        raise e
      end
      if render_hash
        format_type = ModuleDSL.default_format_type()
        content = render_hash.serialize(format_type)
        dsl_filename = ModuleDSL.dsl_filename(config_agent_type,format_type)
        ret.merge!(:path=>dsl_filename, :content=> content)
        if opts[:ret_hash_content]
          ret.merge!(:hash_content => render_hash) 
        end
      end
      raise parsing_error if parsing_error
      ret
    end

    def klass()
      case self.class
        when NodeModule
          NodeModuleDSL
        else
          ModuleDSL
      end
    end

  end
end; end; end
