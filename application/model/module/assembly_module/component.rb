#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK; class AssemblyModule
  class Component < self
    require_relative('component/ad_hoc_link')
    require_relative('component/attribute')
    require_relative('component/get')
    include Get::Mixin

    # opts can have keys
    #  :sha - base sha to create branch from
    #  :ret_module_branch - Boolean
    #  :ret_augmented_module_branch - Boolean
    #  :base_version
    #  :checkout_branch
    #  :donot_update_model
    #  :delete_existing_branch
    def create_module_for_service_instance?(component_module, opts = {})
      fail Error, "Both opts[:ret_augmented_module_branch] and opts[:ret_module_branch] cannot be non null" if opts[:ret_augmented_module_branch] and opts[:ret_module_branch]
      unless component_module.get_workspace_module_branch(self.assembly_module_version)
        base_version = opts[:base_version]        
        create_opts = {
          sha: opts[:sha],
          inherit_frozen_from_base: true,
          checkout_branch: opts[:checkout_branch],
          donot_update_model: opts[:donot_update_model],
          delete_existing_branch: opts[:delete_existing_branch]
        }
        component_module.create_new_version(base_version, self.assembly_module_version, create_opts)
      end
      if opts[:ret_augmented_module_branch]
        component_module.get_augmented_module_branch_with_version(self.assembly_module_version).augment_with_component_module!
      else
        ret = component_module.get_module_repo_info(self.assembly_module_version)
        opts[:ret_module_branch] ? ret[:module_branch_idh].create_object : ret
      end
    end

    # opts can have keys
    #  :base_version
    def self.create_module_for_service_instance__for_pull?(assembly, component_module, opts = {})
      # check if component module base branch exists; it being used to pull component module updates from
      unless base_branch = component_module.get_workspace_branch_info
        fail ErrorNoChangesToModule.new(assembly, component_module)
      end
      am_version = assembly_module_version(assembly)
      unless local_branch = component_module.get_workspace_module_branch(am_version)
        create_module_for_service_instance?(component_module, base_version: opts[:base_version])
        local_branch = component_module.get_workspace_module_branch(am_version)
      end

      base_branch.merge(version: am_version, local_branch: local_branch[:display_name], current_branch_sha: local_branch[:current_sha])
    end

    # opts can have keys:
    #   :meta_file_changed
    #   :service_instance_module
    def self.update_impacted_component_instances(assembly, component_module, nested_module_branch, opts = {})
      new(assembly).update_impacted_component_instances(component_module, nested_module_branch, opts)
    end

    # Update any impacted component instance and recompute module ref locks
    def update_impacted_component_instances(component_module, module_branch, opts = {})
      cmp_instances = get_applicable_component_instances(component_module)
      project_idh = component_module.get_project.id_handle
      begin
        Clone::IncrementalUpdate::Component.new(project_idh, module_branch).update?(cmp_instances, opts)
       rescue Exception => e
        # TODO: DTK-2153: double check that below is still applicable and right
        if sha = opts[:current_branch_sha]
          repo = module_branch.get_repo
          repo.hard_reset_branch_to_sha(module_branch, sha)
          module_branch.set_sha(sha)
        end
        raise e
      end
      # Recompute and persist the module ref locks
      # This must be done after any impacted component instances have been updated
      fail "TODO: DTK-3394: implement when update_impacted_component_instances"
      # ModuleRefs::Lock.create_or_update(self.assembly_instance, opts)
    end

    # opts can have keys
    #  :sha
    #  :version # TODO: change to :base_version
    def self.prepare_for_edit(assembly, component_module, opts = {})
      new(assembly).create_module_for_service_instance?(component_module, sha: opts[:sha], base_version: opts[:version])
    end

    def self.finalize_edit(assembly, component_module, module_branch, opts = {})
      new(assembly).update_impacted_component_instances(component_module, module_branch, opts)
    end

    def self.promote_module_updates_from_nested_branch(service_instance, component_module_name, opts = {})
      base_cmp_branch = service_instance.aug_dependent_base_module_branches.find { |bmb| component_module_name.eql?("#{bmb[:namespace]}/#{bmb[:module_name]}") || component_module_name.eql?("#{bmb[:namespace]}:#{bmb[:module_name]}") }

      fail ErrorUsage.new("Unable to find base module branch for '#{component_module_name}'!") unless base_cmp_branch

      new(service_instance.assembly_instance).promote_module_updates(base_cmp_branch.component_module, opts)
    end

    def self.promote_module_updates(assembly, component_module, opts = {})
      new(assembly).promote_module_updates(component_module, opts)
    end

    def promote_module_updates(component_module, opts = {})
      unless branch = component_module.get_workspace_module_branch(self.assembly_module_version)
        fail ErrorNoChangesToModule.new(self.assembly_instance, component_module)
      end
      unless ancestor_branch = branch.get_ancestor_branch?
        fail Error.new('Cannot find ancestor branch')
      end
      branch_name = branch[:branch]

      fail ErrorUsage.new("You are not allowed to update specific component module version!") if branch[:frozen] || ancestor_branch[:frozen]

      ancestor_branch.merge_changes_and_update_model?(component_module, branch_name, opts)
    end

    def self.list_remote_diffs(_model_handle, module_id, repo, module_branch, workspace_branch, opts)
      diffs = []
      diff = nil
      remote_repo_cols = [:id, :display_name, :version, :remote_repos, :dsl_parsed]
      project_idh      = opts[:project_idh]

      filter =
        if ancestor_id = module_branch.get_field?(:ancestor_id)
          [:eq, :id, ancestor_id]
        else
          [:and,
           [:eq, :type, 'component_module'],
           [:eq, :version, ModuleBranch.version_field_default],
           [:eq, :repo_id, repo.id],
           [:eq, :component_id, module_id]
          ]
        end

      sp_hash = {
        cols: [:id, :group_id, :display_name, :component_type],
        filter: filter
      }
      base_branch = Model.get_obj(module_branch.model_handle, sp_hash)
      diff = repo.get_local_branches_diffs(module_branch, base_branch, workspace_branch)

      diff.each do |diff_obj|
        path = "diff --git a/#{diff_obj.a_path} b/#{diff_obj.b_path}\n"
        diffs << (path + "#{diff_obj.diff}\n")
      end

      diffs
    end

    def self.dependent_modules_relationship(service_instance, opts = {})
      base_cmp_branches = service_instance.aug_dependent_base_module_branches
      new(service_instance.assembly_instance).dependent_modules_relationship(base_cmp_branches, opts)
    end

    def dependent_modules_relationship(base_cmp_branches, opts = {})
      ret = []

      base_cmp_branches.each do |base_cmp_branch|
        cmp_ret = {
          id: base_cmp_branch[:component_id], # component module id
          full_name: "#{base_cmp_branch[:namespace]}:#{base_cmp_branch[:module_name]}",
          display_version: base_cmp_branch[:version]
        }

        component_module = base_cmp_branch.component_module
        unless branch = component_module.get_workspace_module_branch(self.assembly_module_version)
          fail ErrorNoChangesToModule.new(self.assembly_instance, component_module)
        end

        unless ancestor_branch = branch.get_ancestor_branch?
          fail Error.new('Cannot find ancestor branch')
        end

        relationship = RepoManager.ret_merge_relationship(:local_branch, ancestor_branch.display_name, branch)
        cmp_ret.merge!(diff: relationship)

        ret << cmp_ret
      end

      ret
    end

    private

    class ErrorComponentModule < ErrorUsage
      def initialize(assembly, component_module)
        @assembly_name = assembly.display_name_print_form
        @module_name = component_module.get_field?(:display_name)
        super(error_msg)
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
