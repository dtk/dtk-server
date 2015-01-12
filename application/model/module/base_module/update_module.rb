module DTK; class BaseModule
  class UpdateModule
    r8_nested_require('update_module','import')
    r8_nested_require('update_module','clone_changes')
    r8_nested_require('update_module','update_module_refs')
    r8_nested_require('update_module','external_refs')
    r8_nested_require('update_module','external_refs')
    r8_nested_require('update_module','create')
    r8_nested_require('update_module','scaffold_implementation')
    include CreateMixin

    def initialize(base_module)
      @base_module  = base_module
      @module_class = base_module.class
    end

    ####### mixin public methods #########
    module Mixin
      def import_from_puppet_forge(config_agent_type,impl_obj,component_includes)
        Import.new(self).import_from_puppet_forge(config_agent_type,impl_obj,component_includes)
      end
      
      def import_from_git(commit_sha,repo_idh,version,opts={})
        Import.new(self,version).import_from_git(commit_sha,repo_idh,opts)
      end
      
      def import_from_file(commit_sha,repo_idh,version,opts={})
        Import.new(self,version).import_from_file(commit_sha,repo_idh,opts)
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
      ScaffoldImplementation.create_dsl(module_name(),config_agent_type,impl_obj)
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

      # TODO: check if this fails whether it raises a parsing error
      # if outer layer catches these then this form ais good and want to remove otehrs
      # to raise errors rather than passing error obejct
      # with error
      dsl_obj.update_model_with_ref_integrity_check(:version => version)

      if opts[:update_from_includes]
        ret = UpdateModuleRefs.new(dsl_obj,@base_module).validate_includes_and_update_module_refs()
        return ret if is_parsing_error?(ret)
      end

      external_deps = ret[:external_dependencies]

      unless opts[:skip_module_ref_update]
        opts_save_dsl = Opts.create?(:message? => ret[:message],:external_dependencies? => external_deps)
        if dsl_updated_info = UpdateModuleRefs.save_dsl?(module_branch,opts_save_dsl)
          if opts[:ret_dsl_updated_info]
            opts[:ret_dsl_updated_info] = dsl_updated_info
          end
        end
      end

      # ret is initially set to Hash.new and can only be changed if opts[:update_from_includes] meaning
      # that validate_includes_and_update_module_refs wil be called
      # for that reason we have the following short circuit
      return ret unless opts[:update_from_includes]
      
      # For Rich: not sure if you use 'or' on purpose here but in this case when using 'or' instead of '||'
      # no_errors will have value which is returned by dependencies.nil? because operator '=' is 'older'
      # that 'or' (but 'younger' than '||')
      # e.g. if dependencies.nil? is false, but !dependencies.any_errors?() is true, no_errors will still have value = false
      # but if use '||' instead of 'or' then it will act like this no_errors = (dependencies.nil? or !dependencies.any_errors?())
      # and for the example above no_errors will have value true, which is correct
      #
      # no_errors = dependencies.nil? or !dependencies.any_errors?()
      # TODO: For Aldin: area to clean up
      no_errors = external_deps.nil? || !external_deps.any_errors?()
      if no_errors and !opts[:dsl_parsed_false]
        set_dsl_parsed!(true)
      end
      # TODO: can we find better way to pass :external_dependencies and passing ret rather than 'ret unless no_errors'
      opts[:external_dependencies] = external_deps if external_deps
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

    def klass()
      case @module_class
        when NodeModule
          NodeModuleDSL
        else
          ModuleDSL
      end
    end

    def ret_local(version)
      self.class.ret_local(@base_module,version)
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
    def is_parsing_error?(response)
      ModuleDSL::ParsingError.is_error?(response)
    end

  end
end; end

