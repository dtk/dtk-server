module DTK; class BaseModule
  class UpdateModule
    r8_nested_require('update_module','import')
    r8_nested_require('update_module','clone_changes')
    r8_nested_require('update_module','update_module_refs')
    r8_nested_require('update_module','external_refs')
    r8_nested_require('update_module','external_refs')
    r8_nested_require('update_module','create')
    include CreateMixin

    def initialize(base_module)
      @base_module = base_module
    end

    ####### mixin public methods #########
    module Mixin
      def import_from_puppet_forge(config_agent_type,impl_obj,component_includes)
        Import.new(self).import_from_puppet_forge(config_agent_type,impl_obj,component_includes)
      end
      
      def import_from_git(commit_sha,repo_idh,version,opts={})
        Import.new(self).import_from_git(commit_sha,repo_idh,version,opts)
      end
      
      def import_from_file(commit_sha,repo_idh,version,opts={})
        Import.new(self).import_from_file(commit_sha,repo_idh,version,opts)
      end

      def update_model_from_clone_changes(commit_sha,diffs_summary,module_branch,version,opts={})
        CloneChanges.new(self).update_from_clone_changes(commit_sha,diffs_summary,module_branch,version,opts)
      end

      def parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts={})
        UpdateModule.new(self).parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts)
      end

      # called when installing from dtkn catalog
      # returns nil or parsing error
      def install__process_dsl(repo,module_branch,local,opts={})
        UpdateModule.new(self).install__process_dsl(repo,module_branch,local,opts)
      end

      def pull_from_remote__update_from_dsl(repo, module_and_branch_info,version=nil)
        UpdateModule.new(self).pull_from_remote__update_from_dsl(repo, module_and_branch_info,version)
      end

      def create_new_version__type_specific(repo_for_new_branch,new_version,opts={})
        local = UpdateModule.ret_local(self,new_version)
        create_needed_objects_and_dsl?(repo_for_new_branch,local,opts)
      end
    end
    ####### end: mixin public methods #########

    # TODO: for testing
    def test_generate_dsl()
      module_branch = get_module_branch_matching_version()
      config_agent_type = :puppet
      impl_obj = module_branch.get_implementation()
      parse_impl_to_create_dsl(config_agent_type,impl_obj)
    end
    ### end: for testing

    def install__process_dsl(repo,module_branch,local,opts={})
      response = create_needed_objects_and_dsl?(repo,local,opts)
      if is_parsing_error?(response)
        response
      else
        set_dsl_parsed!(true)
        nil
      end
    end

    def pull_from_remote__update_from_dsl(repo, module_and_branch_info,version=nil)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(:repo => repo)
      create_needed_objects_and_dsl?(repo,ret_local(version))
    end

    def parse_dsl_and_update_model(impl_obj,module_branch_idh,version,opts={})
      ret = Hash.new
      set_dsl_parsed!(false)
      module_branch = module_branch_idh.create_object()
      config_agent_type = opts[:config_agent_type] || config_agent_type_default()
      dsl_obj = parse_dsl(impl_obj,opts.merge(:config_agent_type => config_agent_type))
      return dsl_obj if is_parsing_error?(dsl_obj)

      if opts[:update_from_includes]
        ret = UpdateModuleRefs.new(dsl_obj,@base_module).validate_includes_and_update_module_refs()
        return ret if is_parsing_error?(ret)
      end

      dsl_obj.update_model_with_ref_integrity_check(:version => version)

      unless opts[:skip_module_ref_update]
        component_module_refs = ModuleRefs.get_component_module_refs(module_branch)
        serialize_info_hash = (ret[:ambiguous] ? {:ambiguous => ret[:ambiguous]} : Hash.new)
        if new_commit_sha = component_module_refs.serialize_and_save_to_repo?(serialize_info_hash)
          if opts[:ret_dsl_updated_info]
            msg = ret[:message]||"The module refs file was updated by the server"
            opts[:ret_dsl_updated_info] = ModuleDSLInfo::UpdatedInfo.new(:msg => msg,:commit_sha => new_commit_sha)
          end
        end
      end

      # ret is initially set to Hash.new and can only be changed if opts[:update_from_includes] meaning
      # that validate_includes_and_update_module_refs wil be called
      # for that reason we have the following short circuit
      return ret unless opts[:update_from_includes]
      
      dependencies = ret[:external_dependencies]
      # For Rich: not sure if you use 'or' on purpose here but in this case when using 'or' instead of '||'
      # no_errors will have value which is returned by dependencies.nil? because operator '=' is 'older'
      # that 'or' (but 'younger' than '||')
      # e.g. if dependencies.nil? is false, but !dependencies.any_errors?() is true, no_errors will still have value = false
      # but if use '||' instead of 'or' then it will act like this no_errors = (dependencies.nil? or !dependencies.any_errors?())
      # and for the example above no_errors will have value true, which is correct
      #
      # no_errors = dependencies.nil? or !dependencies.any_errors?()

      no_errors = dependencies.nil? || !dependencies.any_errors?()
      if no_errors and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end
      # TODO: can we find better way to pass :external_dependencies and passing ret rather than 'ret unless no_errors'
      opts[:external_dependencies] = dependencies if dependencies
      ret unless no_errors
    end

    def self.ret_local(base_module,version)
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        :module_type => base_module.module_type(),
        :module_name => base_module.module_name(),
        :namespace   => base_module.module_namespace(),
        :version     => version
      )
      local_params.create_local(base_module.get_project())
    end

   private

    # Rich: DTK-1754 pass in an (optional) option that indicates scaffolding strategy
    # will build in flexibility to support a number of varaints in how Puppet as an example
    # gets mapped to a starting point dtk.model.yaml file
    # Initially we wil hace existing stargey for the top level and
    # completely commented out for the component module dependencies
    # As we progress we can identiy two pieces of info
    # 1) what signatures get parsed (e.g., only top level puppet ones) and put in dtk
    # 2) what signatures get parsed and put in commented out
    def parse_impl_to_create_dsl(config_agent_type,impl_obj,opts={})
      ret = ModuleDSLInfo::CreatedInfo.new()
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
      case @base_module.class
        when NodeModule
          NodeModuleDSL
        else
          ModuleDSL
      end
    end

    def ret_local(version)
      self.class.ret_local(@base_module,version)
    end
    def is_parsing_error?(response)
      ModuleDSL::ParsingError.is_error?(response)
    end
    def parse_dsl(impl_obj,opts={})
      klass().parse_dsl(@base_module,impl_obj,opts)
    end
    def update_component_module_refs(module_branch,matching_module_refs)
      UpdateModuleRefs.update_component_module_refs(module_branch,matching_module_refs,@base_module)
    end
    def add_dsl_content_to_impl(impl_obj,dsl_created_info)
      impl_obj.add_file_and_push_to_repo(dsl_created_info[:path],dsl_created_info[:content])
    end

    def set_dsl_parsed!(boolean)
      @base_module.set_dsl_parsed!(boolean)
    end
    def module_namespace()
      @base_module.module_namespace()
    end
    def module_name()
      @base_module.module_name()
    end
    def module_type()
      @base_module.module_type()
    end
    def config_agent_type_default()
      @base_module.config_agent_type_default()
    end
    def get_project()
      @base_module.get_project()
    end

  end
end; end

