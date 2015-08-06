module DTK; class AssemblyModule
  class Component < self
    r8_nested_require('component', 'ad_hoc_link')
    r8_nested_require('component', 'attribute')
    r8_nested_require('component', 'get_for_assembly')

    def self.prepare_for_edit(assembly, component_module, opts = {})
      new(assembly).prepare_for_edit(component_module, opts)
    end
    def prepare_for_edit(component_module, opts = {})
      create_assembly_branch?(component_module, opts)
    end

    def self.component_module_workspace_info(assembly, component_module, opts = {})
      new(assembly).component_module_workspace_info(component_module, opts)
    end
    def component_module_workspace_info(component_module, opts = {})
      am_version = assembly_module_version()

      base_branch = component_module.get_workspace_branch_info()
      fail ErrorNoChangesToModule.new(@assembly, component_module) unless base_branch

      unless local_branch = component_module.get_workspace_module_branch(am_version)
        create_assembly_branch?(component_module, opts)
        local_branch = component_module.get_workspace_module_branch(am_version)
      end

      base_branch.merge!(version: am_version, local_branch: local_branch[:display_name], current_branch_sha: local_branch[:current_sha])
      base_branch
    end

    def self.finalize_edit(assembly, component_module, module_branch, opts = {})
      new(assembly).finalize_edit(component_module, module_branch, opts)
    end
    def finalize_edit(component_module, module_branch, opts = {})
      cmp_instances = get_applicable_component_instances(component_module)
      project_idh = component_module.get_project().id_handle()
      begin
        Clone::IncrementalUpdate::Component.new(project_idh, module_branch).update?(cmp_instances, opts)
      rescue Exception => e
        if sha = opts[:current_branch_sha]
          repo = module_branch.get_repo()
          repo.hard_reset_branch_to_sha(module_branch, sha)
          module_branch.set_sha(sha)
        end

        raise e
      end
    end

    def delete_modules?
      am_version = assembly_module_version()
      # TODO: re-evalaute this no that have ModuleRefs::locacked
      # do not want to use assembly.get_component_modules() to generate component_modules because 
      # there can be modules that do not correspond to component instances
      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_id],
        filter: [:eq, :version, am_version]
      }
      component_module_mh = @assembly.model_handle(:component_module)
      Model.get_objs(@assembly.model_handle(:module_branch), sp_hash).each do |r|
        unless r[:component_id]
          Model.delete_instance(r.id_handle())
          next
        end
        component_module = component_module_mh.createIDH(id: r[:component_id]).create_object()
        component_module.delete_version?(am_version)
      end
    end

    def self.promote_module_updates(assembly, component_module, opts = {})
      new(assembly).promote_module_updates(component_module, opts)
    end

    def promote_module_updates(component_module, opts = {})
      am_version = assembly_module_version()
      unless branch = component_module.get_workspace_module_branch(am_version)
        fail ErrorNoChangesToModule.new(@assembly, component_module)
      end
      unless ancestor_branch = branch.get_ancestor_branch?()
        fail Error.new('Cannot find ancestor branch')
      end
      branch_name = branch[:branch]
      ancestor_branch.merge_changes_and_update_model?(component_module, branch_name, opts)
    end

    def self.get_for_assembly(assembly, opts = {})
      GetForAssembly.new(assembly).get_for_assembly(opts)
    end

    # returns namespace if module_name exists in assembly
    def self.get_namespace?(assembly, module_name)
      Namespace.namespace?(module_name) || ModuleRefs::Lock.get_namespace?(assembly, module_name)
    end

    # returns [namespace, locked_branch_sha] if module_name exists in assembly
    # namespace can at the same time that locked_branch_sha may be nil
    def self.get_namespace_and_locked_branch_sha?(assembly, module_name)
      locked_branch_sha = nil
      if namespace = Namespace.namespace?(module_name)
        locked_branch_sha = ModuleRefs::Lock.get_locked_branch_sha?(assembly, module_name)
      else
        namespace, locked_branch_sha = ModuleRefs::Lock.get_namespace_and_locked_branch_sha?(assembly, module_name)
      end
      [namespace, locked_branch_sha]
    end

    def self.list_remote_diffs(_model_handle, module_id, repo, module_branch, workspace_branch, opts)
      diffs = []
      diff = nil
      remote_repo_cols = [:id, :display_name, :version, :remote_repos, :dsl_parsed]
      project_idh      = opts[:project_idh]

      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_type],
        filter: [:and,
                 [:eq, :type, 'component_module'],
                 [:eq, :version, ModuleBranch.version_field_default()],
                 [:eq, :repo_id, repo.id()],
                 [:eq, :component_id, module_id]
                   ]
      }
      base_branch = Model.get_obj(module_branch.model_handle(), sp_hash)
      diff = repo.get_local_branches_diffs(module_branch, base_branch, workspace_branch)

      diff.each do |diff_obj|
        path = "diff --git a/#{diff_obj.a_path} b/#{diff_obj.b_path}\n"
        diffs << (path + "#{diff_obj.diff}\n")
      end

      diffs
    end

    private

    def create_assembly_branch?(component_module, opts = {})
      am_version = assembly_module_version()
      unless component_module.get_workspace_module_branch(am_version)
        create_assembly_branch(component_module, am_version, opts)
      end
      ret = component_module.get_workspace_branch_info(am_version)
      if opts[:ret_module_branch]
        ret[:module_branch_idh].create_object()
      else
        ret
      end
    end

    def create_assembly_branch(component_module, am_version, opts = {})
      base_version = nil
      component_module.create_new_version(base_version, am_version, opts)
    end

    def get_branch_template(module_branch, cmp_template)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_type],
        filter: [:and, [:eq, :module_branch_id, module_branch.id()],
                 [:eq, :type, 'template'],
                 [:eq, :node_node_id, nil],
                 [:eq, :component_type, cmp_template.get_field?(:component_type)]]
      }
      Model.get_obj(cmp_template.model_handle(), sp_hash) || fail(Error.new('Unexpected that branch_cmp_template is nil'))
    end

    def get_applicable_component_instances(component_module)
      assembly_id = @assembly.id()
      component_module.get_associated_component_instances().select do |cmp|
        cmp[:assembly_id] == assembly_id
      end
    end

    class ErrorComponentModule < ErrorUsage
      def initialize(assembly, component_module)
        @assembly_name = assembly.display_name_print_form()
        @module_name = component_module.get_field?(:display_name)
        super(error_msg())
      end
    end
    class ErrorNoChangesToModule < ErrorComponentModule
      private

      def error_msg
        "Changes to component module (#{@module_name}) have not been made in service instance '#{@assembly_name}'"
      end
    end

  end
end; end
