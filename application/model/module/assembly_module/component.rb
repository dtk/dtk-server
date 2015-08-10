module DTK; class AssemblyModule
  class Component < self
    r8_nested_require('component', 'ad_hoc_link')
    r8_nested_require('component', 'attribute')
    r8_nested_require('component', 'get')
    include Get::Mixin
    extend Get::ClassMixin

    # opts can have keys
    #  :sha
    def self.prepare_for_edit(assembly, component_module, opts = {})
      new(assembly).prepare_for_edit(component_module, opts)
    end
    def prepare_for_edit(component_module, opts = {})
      create_assembly_branch?(component_module, opts)
    end

    def self.create_assembly_module_branch?(assembly, component_module)
      new(assembly).create_assembly_module_branch?(component_module)
    end
    def create_assembly_module_branch?(component_module)
      am_version = assembly_module_version()

      # check if component module base branch exist; it being used to pull component module updates from
      unless base_branch = component_module.get_workspace_branch_info()
        fail ErrorNoChangesToModule.new(@assembly, component_module)
      end

      unless local_branch = component_module.get_workspace_module_branch(am_version)
        create_assembly_branch?(component_module)
        local_branch = component_module.get_workspace_module_branch(am_version)
      end

      base_branch.merge(version: am_version, local_branch: local_branch[:display_name], current_branch_sha: local_branch[:current_sha])
    end

    def self.finalize_edit(assembly, component_module, module_branch, opts = {})
      new(assembly).finalize_edit(component_module, module_branch, opts)
    end
    def finalize_edit(component_module, module_branch, opts = {})
      # Update any impacted component instance
      cmp_instances = get_applicable_component_instances(component_module)
      project_idh = component_module.get_project().id_handle()
      begin
        Clone::IncrementalUpdate::Component.new(project_idh, module_branch).update?(cmp_instances, opts)
       rescue Exception => e
        # TODO: DTK-2153: double check that below is still applicable and right
        if sha = opts[:current_branch_sha]
          repo = module_branch.get_repo()
          repo.hard_reset_branch_to_sha(module_branch, sha)
          module_branch.set_sha(sha)
        end
        raise e
      end
      # Recompute and persist the module ref locks
      # This must be done after any impacted component instances have been updated
      ModuleRefs::Lock.compute(@assembly).persist
    end

    def delete_modules?
      am_version = assembly_module_version()
      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_id],
        filter: [:eq, :version, am_version]
      }
      component_module_mh = @assembly.model_handle(:component_module)

      # iterate over any service or component module branch that has been created for the service instance
      Model.get_objs(@assembly.model_handle(:module_branch), sp_hash).each do |module_branch|
        # if module_branch[:component_id] is nil then this is a service module branch, otherwise it is a component module branch
        if module_branch[:component_id].nil?
          Model.delete_instance(module_branch.id_handle())
        else
          component_module = component_module_mh.createIDH(id: module_branch[:component_id]).create_object()
          component_module.delete_version?(am_version)
        end
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

    # opts can have keys
    #  :sha - base sha to create branch from
    #  :ret_module_branch - Boolean
    #  :module_branch_idh (required if ret_module_branch == true)
    def create_assembly_branch?(component_module, opts = {})
      am_version = assembly_module_version()
      unless component_module.get_workspace_module_branch(am_version)
        create_assembly_branch(component_module, am_version, Aux.hash_subset(opts, [:sha]))
      end
      ret = component_module.get_workspace_branch_info(am_version)
      opts[:ret_module_branch] ? ret[:module_branch_idh].create_object() : ret
    end

    # opts can have keys
    #  :sha - base sha to create branch from
    def create_assembly_branch(component_module, am_version, opts = {})
      base_version = nil
      component_module.create_new_version(base_version, am_version, opts)
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
