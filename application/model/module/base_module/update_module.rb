# TODO: may cleanup: in some methods raise parsing errors and others pass back errors
# if dont want to find multiple errors on single pass we can simplify by having all raise errors and then remove all
# the statements that check whether responds is a parsing error (an usually return imemdiately; so not detecting multiple erros)
module DTK; class BaseModule
  class UpdateModule
    r8_nested_require('update_module', 'puppet_forge')
    r8_nested_require('update_module', 'import')
    r8_nested_require('update_module', 'clone_changes')
    r8_nested_require('update_module', 'update_module_refs')
    r8_nested_require('update_module', 'external_refs')
    r8_nested_require('update_module', 'external_refs')
    r8_nested_require('update_module', 'create')
    r8_nested_require('update_module', 'scaffold_implementation')
    include CreateMixin

    def initialize(base_module)
      @base_module  = base_module
      @module_class = base_module.class
    end

    ####### mixin public methods #########
    module ClassMixin
      def import_from_puppet_forge(project, puppet_forge_local_copy, opts = {})
        PuppetForge.new(project, puppet_forge_local_copy, opts).import_module_and_missing_dependencies()
      end
    end

    module Mixin
      def import_from_git(commit_sha, repo_idh, version, opts = {})
        Import.new(self, version).import_from_git(commit_sha, repo_idh, opts)
      end

      def import_from_file(commit_sha, repo_idh, version, opts = {})
        Import.new(self, version).import_from_file(commit_sha, repo_idh, opts)
      end

      def update_model_from_clone_changes(commit_sha, diffs_summary, module_branch, version, opts = {})
        CloneChanges.new(self).update_from_clone_changes(commit_sha, diffs_summary, module_branch, version, opts)
      end

      def parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts = {})
        UpdateModule.new(self).parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts)
      end

      # called when installing from dtkn catalog
      # returns nil or parsing error
      def install__process_dsl(repo, module_branch, local, opts = {})
        # Skipping module_ref_update since module being isntalled has this set already so just copy this in
        opts = { update_module_refs_from_file: true }.merge(opts)
        UpdateModule.new(self).install__process_dsl(repo, module_branch, local, opts)
      end

      def pull_from_remote__update_from_dsl(repo, module_and_branch_info, version = nil)
        UpdateModule.new(self).pull_from_remote__update_from_dsl(repo, module_and_branch_info, version)
      end

      # returns the new module branch
      # This is caledd when cerating a service insatnce specific component module
      def create_new_version__type_specific(repo_for_new_branch, new_version, opts = {})
        local = UpdateModule.ret_local(self, new_version)
        # TODO: this is expensive in that it creates new version by parsing the dsl and reading back in;
        # would be much less expsensive to clone from branch to branch
        opts_update = { update_module_refs_from_file: true }.merge(opts)
        response = UpdateModule.new(self).create_needed_objects_and_dsl?(repo_for_new_branch, local, opts_update)
        response[:module_branch_idh].create_object()
      end
    end
    ####### end: mixin public methods #########

    def install__process_dsl(repo, module_branch, local, opts = {})
      response = create_needed_objects_and_dsl?(repo, local, opts)
      if is_parsing_error?(response)
        response
      else
        module_branch.set_dsl_parsed!(true)
        nil
      end
    end

    def pull_from_remote__update_from_dsl(repo, module_and_branch_info, version = nil)
      info = module_and_branch_info #for succinctness
      module_branch_idh = info[:module_branch_idh]
      module_branch = module_branch_idh.create_object().merge(repo: repo)
      create_needed_objects_and_dsl?(repo, ret_local(version))
    end

    # only returns non nil if passring error; it traps parsing errors
    def parse_dsl_and_update_model_with_err_trap(impl_obj, module_branch_idh, version, opts = {})
      klass()::ParsingError.trap(only_return_error: true) { parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts) }
    end

    def parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts = {})
      ret = {}
      module_branch = module_branch_idh.create_object()

      module_branch.set_dsl_parsed!(false)
      config_agent_type = opts[:config_agent_type] || config_agent_type_default()
      # TODO: for efficiency can change parse_dsl to take option opts[:dsl_created_info]
      dsl_obj = parse_dsl(impl_obj, opts.merge(config_agent_type: config_agent_type))
      return dsl_obj if is_parsing_error?(dsl_obj)

      dsl_obj.update_model_with_ref_integrity_check(version: version)

      if opts[:update_from_includes]
        ret = UpdateModuleRefs.new(dsl_obj, @base_module).validate_includes_and_update_module_refs()
        return ret if is_parsing_error?(ret)
      end

      external_deps = ret[:external_dependencies]

      if opts[:update_module_refs_from_file]
        # updating module refs from the component_module_ref file
        ModuleRefs::Parse.update_component_module_refs(@module_class, module_branch)
      else
        opts_save_dsl = Opts.create?(message?: ret[:message], external_dependencies?: external_deps)
        if dsl_updated_info = UpdateModuleRefs.save_dsl?(module_branch, opts_save_dsl)
          if opts[:ret_dsl_updated_info]
            opts[:ret_dsl_updated_info] = dsl_updated_info
          end
        end
      end

      # TODO: see if can simplify and make this an 'else' to opts[:update_from_includes above
      unless opts[:update_from_includes]
        module_branch.set_dsl_parsed!(true) if !opts[:dsl_parsed_false]
        return ret
      end

      no_errors = external_deps.nil? || !external_deps.any_errors?()
      if no_errors && !opts[:dsl_parsed_false]
        module_branch.set_dsl_parsed!(true)
      end

      opts[:external_dependencies] = external_deps if external_deps
      ret unless no_errors
    end

    def self.ret_local(base_module, version)
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        module_type: base_module.module_type(),
        module_name: base_module.module_name(),
        namespace: base_module.module_namespace(),
        version: version
      )
      local_params.create_local(base_module.get_project())
    end

    def add_dsl_to_impl_and_create_objects(dsl_created_info, project, impl_obj, module_branch_idh, version, opts = {})
      impl_obj.add_file_and_push_to_repo(dsl_created_info[:path], dsl_created_info[:content])
      opts.merge!(project: project, dsl_created_info: dsl_created_info)
      parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts)
    end

    private

    def klass
      case @module_class
        when NodeModule
          NodeModuleDSL
        else
          ModuleDSL
      end
    end

    def ret_local(version)
      self.class.ret_local(@base_module, version)
    end

    def parse_dsl(impl_obj, opts = {})
      klass().parse_dsl(@base_module, impl_obj, opts)
    end

    def update_component_module_refs(module_branch, matching_module_refs)
      UpdateModuleRefs.update_component_module_refs(module_branch, matching_module_refs, @base_module)
    end

    def set_dsl_parsed!(boolean)
      @base_module.set_dsl_parsed!(boolean)
    end

    def module_namespace
      @base_module.module_namespace()
    end

    def module_name
      @base_module.module_name()
    end

    def module_type
      @base_module.module_type()
    end

    def config_agent_type_default
      @base_module.config_agent_type_default()
    end

    def get_project
      @base_module.get_project()
    end

    def is_parsing_error?(response)
      ModuleDSL::ParsingError.is_error?(response)
    end
  end
end; end
