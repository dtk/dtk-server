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
      def process_dsl_and_ret_parsing_errors(repo, module_branch, local, opts = {})
        # Skipping module_ref_update since module being isntalled has this set already so just copy this in
        opts = { update_module_refs_from_file: true }.merge(opts)
        UpdateModule.new(self).process_dsl_and_ret_parsing_errors(repo, module_branch, local, opts)
      end

      # returns the new module branch
      # This is caledd when creating a service instance specific component module
      def create_new_version__type_specific(repo_for_new_branch, new_version, opts = {})
        local = UpdateModule.ret_local(self, new_version, opts)
        # TODO: this is expensive in that it creates new version by parsing the dsl and reading back in;
        # would be much less expsensive to clone from branch to branch
        opts_update = { update_module_refs_from_file: true }.merge(opts)
        response = UpdateModule.new(self).create_needed_objects_and_dsl?(repo_for_new_branch, local, opts_update)
        response[:module_branch_idh].create_object()
      end
    end
    ####### end: mixin public methods #########

    def process_dsl_and_ret_parsing_errors(repo, module_branch, local, opts = {})
      response = create_needed_objects_and_dsl?(repo, local, opts)
      if is_parsing_error?(response)
        response
      else
        module_branch.set_dsl_parsed!(true)
        nil
      end
    end

    # only returns non nil if parsing error; it traps parsing errors
    def parse_dsl_and_update_model(impl_obj, module_branch_idh, version, opts = {})
      ret = nil
      module_branch = module_branch_idh.create_object()

      if version && !version.eql?('') && !version.eql?('master')
        unless version = ::DTK::ModuleVersion.ret(version)
          fail ::DTK::ErrorUsage::BadVersionValue.new(remote_params.version)
        end
      end

      module_branch.set_dsl_parsed!(false)
      config_agent_type = opts[:config_agent_type] || config_agent_type_default()

      # TODO: for efficiency can change parse_dsl to take option opts[:dsl_created_info]
      dsl_obj = parse_dsl(impl_obj, opts.merge(config_agent_type: config_agent_type))
      return dsl_obj if is_parsing_error?(dsl_obj)

      opts[:ret_parsed_dsl].add(dsl_obj) if opts[:ret_parsed_dsl]

      dsl_obj.update_model_with_ref_integrity_check(version: version)

      update_from_includes = {}
      no_errors = true
      if opts[:update_from_includes]
        # Can be both parsing errors, in which case is_parsing_error?(update_from_includes) i strue
        # or can be dependency errors in which case external_deps.any_errors?() is true
        # If external_deps.any_errors?() error dont yet return so can execute UpdateModuleRefs.save_dsl?
        update_from_includes = UpdateModuleRefs.new(dsl_obj, @base_module).validate_includes_and_update_module_refs()
        return update_from_includes if is_parsing_error?(update_from_includes)

        if external_deps = update_from_includes[:external_dependencies]
          opts[:external_dependencies] = external_deps
          if external_deps.any_errors?()
            ret = update_from_includes 
            no_errors = false
          end
        end
      end

      # TODO: double check if opts[:update_from_includes] and opts[:update_module_refs_from_file] mutually exclusive
      if opts[:update_module_refs_from_file]
        # updating module refs from the component_module_ref file
        ModuleRefs::Parse.update_component_module_refs(@module_class, module_branch)
      else
        opts_save_dsl = Opts.create?(message?: update_from_includes[:message], external_dependencies?: external_deps)
        if dsl_updated_info = UpdateModuleRefs.save_dsl?(module_branch, opts_save_dsl)
          if opts[:ret_dsl_updated_info]
            opts[:ret_dsl_updated_info] = dsl_updated_info
          end
        end
      end

      unless opts[:update_from_includes]
        module_branch.set_dsl_parsed!(true) unless opts[:dsl_parsed_false]
        return ret
      end

      if no_errors && !opts[:dsl_parsed_false]
        module_branch.set_dsl_parsed!(true)
      end

      ret
    end

    def self.ret_local(base_module, version, opts = {})
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        module_type: base_module.module_type(),
        module_name: base_module.module_name(),
        namespace: base_module.module_namespace(),
        version: version
      )
      local_params.create_local(base_module.get_project(), opts)
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
