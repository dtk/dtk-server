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
module DTK
  module ModuleCommonMixin
    module GetBranchMixin
      def get_module_branch_from_local_params(local_params)
        self.class.get_module_branch_from_local(local_params.create_local(get_project()))
      end

      def get_module_branches
        get_objs_helper(:module_branches, :module_branch)
      end

      def get_module_branch_matching_version(version = nil)
        get_module_branches().find { |mb| mb.matches_version?(version) }
      end

      def get_workspace_repo(version = nil)
        get_augmented_module_branch_with_version(version)[:repo]
      end

      def get_module_repo_info(version = nil, opts = {})
        if aug_branch = get_augmented_module_branch_with_version(version, opts)
          module_name = aug_branch[:module_name]
          module_namespace = aug_branch[:module_namespace]
          opts_info = { version: version, module_namespace: module_namespace }
          ModuleRepoInfo.new(aug_branch[:repo], module_name, id_handle(), aug_branch, opts_info)
        end
      end

      def get_augmented_module_branch(opts = {})
        ModuleBranch::Augmented.get_augmented_module_branch(self, opts)
      end
      def get_augmented_module_branch_with_version(version = nil, opts = {})
        get_augmented_module_branch(opts.merge(filter: { version: version }))
      end

      # TODO: deprecate get_workspace_branch_info for get_module_repo_info
      def get_workspace_branch_info(version = nil, opts = {})
        get_module_repo_info(version, opts)
      end

      # TODO: :library call should be deprecated
      # type is :library or :workspace
      def find_branch(type, branches)
        matches =
          case type
          when :library then branches.reject { |r| r[:is_workspace] }
          when :workspace then branches.select { |r| r[:is_workspace] }
          else fail Error.new("Unexpected type (#{type})")
          end
      if matches.size > 1
        Error.new("Unexpected that there is more than one matching #{type} branches")
      end
        matches.first
      end

      #
      # Returns ModuleBranch object for given version
      #
      def get_workspace_module_branch(version = nil)
        mb_mh = model_handle().create_childMH(:module_branch)
        sp_hash = {
        cols: ModuleBranch.common_columns(),
        filter: [:and, [:eq, mb_mh.parent_id_field_name(), id()],
                 [:eq, :is_workspace, true],
                 [:eq, :version, ModuleBranch.version_field(version)]]
      }
        Model.get_obj(mb_mh, sp_hash)
      end
      # MOD_RESTRUCT: may replace below with above
      def get_module_branch(branch)
        sp_hash = {
          cols: [:module_branches]
        }
        module_branches = get_objs(sp_hash).map { |r| r[:module_branch] }
        module_branches.find { |mb| mb[:branch] == branch }
      end
    end

    module GetBranchClassMixin
      def get_augmented_module_branch_from_local(local)
        aug_module_branch = ModuleBranch::Augmented.create_from_module_branch(get_module_branch_from_local(local))
        aug_module_branch.augment_with_component_module! if local.module_type == :component_module

        aug_module_branch
      end

      # opts can have keys: 
      #   :no_error_if_does_not_exist
      def get_module_branch_from_local(local, opts = {})
        project = local.project()
        project_idh = project.id_handle()
        module_match_filter =
          if local_namespace = local.module_namespace_name()
            [:eq, :ref, Namespace.module_ref_field(local.module_name(), local_namespace)]
          else
            [:eq, :display_name, local.module_name]
          end
        filter = [:and, module_match_filter, [:eq, :project_project_id, project_idh.get_id()]]
        branch = local.branch_name()
        post_filter = proc { |mb| mb[:branch] == branch }
        matches = get_matching_module_branches(project_idh, filter, post_filter, no_error_if_does_not_exist: opts[:no_error_if_does_not_exist])
        if matches.size == 0
          nil
        elsif matches.size == 1
          matches.first
        elsif matches.size > 1
          fail Error.new("Matched rows has unexpected size (#{matches.size}) since its is >1")
        end
      end

      # TODO: ModuleBranch::Location: deprecate below for above
      def get_workspace_module_branch(project, module_name, version = nil, namespace = nil, opts = {})
        project_idh = project.id_handle()
        filter  = [:and, [:eq, :display_name, module_name], [:eq, :project_project_id, project_idh.get_id()]]
        filter = filter.push([:eq, :namespace_id, namespace.id()]) if namespace
        branch = ModuleBranch.workspace_branch_name(project, version)
        post_filter = proc { |mb| mb[:branch] == branch }
        matches = get_matching_module_branches(project_idh, filter, post_filter, opts)
        if matches.size == 0
          nil
        elsif matches.size == 1
          matches.first
        elsif matches.size > 1
          Log.error_pp(['Matched rows:', matches])
          fail Error.new("Matched rows has unexpected size (#{matches.size}) since its is >1")
        end
      end

      def get_workspace_module_branches(module_idhs)
        ret = []
        if module_idhs.empty?
          return ret
        end
        mh = module_idhs.first.createMH()
        filter = [:oneof, :id, module_idhs.map(&:get_id)]
        post_filter = proc { |mb| !mb.assembly_module_version?() }
        get_matching_module_branches(mh, filter, post_filter)
      end

      def get_matching_module_branches(mh_or_idh, filter, post_filter = nil, opts = {})
        sp_hash = {
            cols: [:id, :display_name, :group_id, :module_branches],
            filter: filter
        }
        rows = get_objs(mh_or_idh.create_childMH(model_type()), sp_hash).map do |r|
          r[:module_branch].merge(module_id: r[:id])
        end
        if rows.empty?
          return [] if opts[:no_error_if_does_not_exist]
          fail ErrorUsage.new('Module does not exist')
        end
        post_filter ? rows.select { |r| post_filter.call(r) } : rows
      end

    end
  end
end
