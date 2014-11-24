#TODO: Aldin: think you want to replace cases where there is an instance function that uses ModuleDSL
#with klass(self)
module DTK
  class DSLInfo < Hash
    def initialize(hash={})
      super()
      replace(hash)
    end
    def dsl_parsed_info=(dsl_parsed_info)
      merge!(:dsl_parsed_info => dsl_parsed_info)
      dsl_parsed_info
    end
    def dsl_created_info=(dsl_created_info)
      merge!(:dsl_created_info => dsl_created_info)
      dsl_created_info
    end
    def dsl_updated_info=(dsl_updated_info)
      merge!(:dsl_updated_info => dsl_updated_info)
      dsl_updated_info
    end
  end
  # has info if DSL file is created and being passed to
  class DSLCreatedInfo < Hash
    def self.create_empty()
      new()
    end
    def self.create_with_path_and_content(path,content)
      new(:path => path, :content => content)
    end
   private
    def initialize(hash={})
      super()
      replace(hash)
    end
  end
  class DSLUpdatedInfo < Hash
    def initialize(msg,commit_sha)
      super()
      replace(:msg => msg, :commit_sha => commit_sha)
    end
  end
end

module DTK; class BaseModule
  module DSLMixin
    r8_nested_require('dsl_mixin','external_refs')
    include ExternalRefsMixin

    def install__process_dsl(repo,module_branch,local,opts={})
      parsed = create_needed_objects_and_dsl?(repo,local,opts)
      parsed
    end

    def update_from_initial_create(commit_sha,repo_idh,version,opts={})
      ret = DSLInfo.new()
      module_branch = get_workspace_module_branch(version)
      pull_was_needed = module_branch.pull_repo_changes?(commit_sha)

      parse_needed = !dsl_parsed?()
      return ret unless pull_was_needed or parse_needed
      repo = repo_idh.create_object()
      deprecate_create_needed_objects_and_dsl?(repo,version,opts)
    end

    def create_new_dsl_version(new_dsl_integer_version,format_type,module_version)
      unless new_dsl_integer_version == 2
        raise Error.new("component_module.create_new_dsl_version only implemented when target version is 2")
      end
      previous_dsl_version = new_dsl_integer_version-1
      module_branch = get_module_branch_matching_version(module_version)

      # create in-memory dsl object using old version
      component_dsl = ModuleDSL.create_dsl_object(module_branch,previous_dsl_version)
      # create from component_dsl the new version dsl
      dsl_paths_and_content = component_dsl.migrate(module_name(),new_dsl_integer_version,format_type)
      module_branch.serialize_and_save_to_repo?(dsl_paths_and_content)
    end

    def pull_from_remote__update_from_dsl(repo, module_and_branch_info,version=nil)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo)

      deprecate_create_needed_objects_and_dsl?(repo,version)
    end

    def parse_dsl_and_update_model(impl_obj,module_branch_idh,version=nil,namespace=nil,opts={})
      set_dsl_parsed!(false)

      module_branch = module_branch_idh.create_object()
      component_module_refs = klass(self).update_component_module_refs(self.class,module_branch,opts)
      return component_module_refs if ModuleDSL::ParsingError.is_error?(component_module_refs)

      v_namespaces = klass(self).validate_module_ref_namespaces(module_branch,component_module_refs)
      return v_namespaces if ModuleDSL::ParsingError.is_error?(v_namespaces)

      opts.merge!(:component_module_refs => component_module_refs)
      klass(self).parse_and_update_model(self,impl_obj,module_branch_idh,version,namespace,opts)
      set_dsl_parsed!(true)
    end

    # TODO: for testing
    def test_generate_dsl()
      module_branch = get_module_branch_matching_version()
      config_agent_type = :puppet
      impl_obj = module_branch.get_implementation()
      parse_impl_to_create_dsl(config_agent_type,impl_obj)
    end
    ### end: for testing

  private
    def create_new_version__type_specific(repo_for_new_branch,new_version,opts={})
      # TODO: push use of local from calling fn
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        :module_type => module_type(),
        :module_name => module_name(),
        :namespace   => module_namespace(),
        :version => new_version
      )
      local = local_params.create_local(get_project())
      create_needed_objects_and_dsl?(repo_for_new_branch,local,opts)
    end

    def update_model_from_clone__type_specific?(commit_sha,diffs_summary,module_branch,version,opts={})
      update_model_objs_or_create_dsl?(diffs_summary,module_branch,version,opts)
    end

    def deprecate_create_needed_objects_and_dsl?(repo,version,opts={})
      # TODO: used temporarily until get all callers to use local object
      local = deprecate_ret_local(version)
#      Log.info_pp(["TODO: Using deprecate_create_needed_objects_and_dsl?; local =",local,caller[0..4]])
      create_needed_objects_and_dsl?(repo,local,opts)
    end
    def deprecate_ret_local(version)
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        :module_type => module_type(),
        :module_name => module_name(),
        :namespace   => module_namespace(),
        :version => version
      )
      local_params.create_local(get_project())
    end
    def create_needed_objects_and_dsl?(repo,local,opts={})
      ret = DSLInfo.new()
      module_name = local.module_name
      branch_name = local.branch_name
      module_namespace = local.module_namespace_name
      version = local.version
      project = local.project
      config_agent_type = config_agent_type_default()
      impl_obj = Implementation.create_workspace_impl?(project.id_handle(),repo,module_name,config_agent_type,branch_name,version,module_namespace)
      impl_obj.create_file_assets_from_dir_els()

      module_and_branch_info = self.class.create_module_and_branch_obj?(project,repo.id_handle(),local,opts[:ancestor_branch_idh])
      module_branch_idh = module_and_branch_info[:module_branch_idh]
      external_dependencies = matching_branches = nil
      # opts[:process_external_refs] means to see if external refs and then check againts existing loaded components
      if opts[:process_external_refs]
        module_branch = module_branch_idh.create_object()
        if external_deps = process_external_refs(module_branch,config_agent_type,project,impl_obj)
          if poss_problems = external_deps.possible_problems?()
            ret.merge!(:external_dependencies => poss_problems)
          end
          matching_branches = external_deps.matching_module_branches?()
        end
      # opts[:set_external_refs] means to set external refs if they exist from parsing module files
      elsif opts[:set_external_refs]
        module_branch = module_branch_idh.create_object()
        set_external_ref?(module_branch,config_agent_type,impl_obj)
      end

      dsl_created_info = DSLCreatedInfo.create_empty()
      klass = klass(self)
      if klass.contains_dsl_file?(impl_obj)
        if e = klass::ParsingError.trap{parse_dsl_and_update_model(impl_obj,module_branch_idh,version,module_namespace,opts)}
          ret.dsl_parsed_info = e
        end
      elsif opts[:scaffold_if_no_dsl]
        opts = Hash.new
        if matching_branches
          opts.merge!(:include_module_branches => matching_branches)
        end
        dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj,opts)
      end
      ret.merge!(:module_branch_idh => module_branch_idh, :dsl_created_info => dsl_created_info)
      ret
    end
    def update_model_objs_or_create_dsl?(diffs_summary,module_branch,version,opts={})
      ret = DSLInfo.new()
      dsl_created_info = DSLCreatedInfo.create_empty()
      module_namespace = module_namespace()
      impl_obj = module_branch.get_implementation()
      # TODO: make more robust to handle situation where diffs dont cover all changes; think can detect by looking at shas
      impl_obj.modify_file_assets(diffs_summary)

      if version.kind_of?(ModuleVersion::AssemblyModule)

        if meta_file_changed = diffs_summary.meta_file_changed?()
          parse_dsl_and_update_model(impl_obj,module_branch.id_handle(),version,module_namespace,opts)
        end
        assembly = version.get_assembly(model_handle(:component))
        opts_finalize = (meta_file_changed ? {:meta_file_changed => true} : {})
        AssemblyModule::Component.finalize_edit(assembly,self,module_branch,opts_finalize)
      elsif ModuleDSL.contains_dsl_file?(impl_obj)
        if opts[:force_parse] or diffs_summary.meta_file_changed?() or (get_field?(:dsl_parsed) == false)
          if e = ModuleDSL::ParsingError.trap{parse_dsl_and_update_model(impl_obj,module_branch.id_handle(),version,module_namespace,opts)}
            ret.dsl_parsed_info = e
          end
        end
      else
        config_agent_type = config_agent_type_default()
        dsl_created_info = parse_impl_to_create_dsl(config_agent_type,impl_obj)
      end
      ret.dsl_created_info = dsl_created_info
      ret
    end

    def parse_impl_to_create_dsl(config_agent_type,impl_obj,opts={})
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
        ret = DSLCreatedInfo.create_with_path_and_content(dsl_filename, content)
      end
      raise parsing_error if parsing_error
      ret
    end

    def klass(klass)
      case klass
        when NodeModule
          return NodeModuleDSL
        else
          return ModuleDSL
        end
    end

  end
end; end
