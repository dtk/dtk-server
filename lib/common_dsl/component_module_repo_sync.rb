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
  module CommonDSL
    # Methods to sync to and from the service instance repo to the component module repos using git subtree operations
    class ComponentModuleRepoSync
      require_relative('component_module_repo_sync/common')
      require_relative('component_module_repo_sync/transform')

      def initialize(service_module_branch)
        @service_module_branch = service_module_branch
      end
      private :initialize

      def self.push_to_component_module(service_module_branch, aug_component_module_branch, nested_module_info)
        new(service_module_branch).push_to_component_module(aug_component_module_branch, nested_module_info)
      end
      def push_to_component_module(aug_component_module_branch, nested_module_info)
        Transform::SyncBranch.update_and_transform(@service_module_branch, sync_branch_name, nested_module_info)
        git_subtrees_push_from_sync_branch(aug_component_module_branch)
      end

      def self.pull_from_component_modules(service_module_branch, aug_component_module_branches)
        return if aug_component_module_branches.empty?
        new(service_module_branch).pull_from_component_modules(aug_component_module_branches)
      end
      def pull_from_component_modules(aug_component_module_branches)
        git_subtrees_pull_from_component_modules(aug_component_module_branches)
        Transform::ServiceInstance.transform_nested_modules(service_module_branch, aug_component_module_branches)
      end

      def self.delete_sync_repo_branch?(service_module_branch)
        raise Error, "Write delete_sync_branch?"
      end

      private

      attr_reader :service_module_branch

      def git_subtrees_pull_from_component_modules(aug_component_module_branches)
        # create branch to directly push pull from
        RepoManager.add_branch?(sync_branch_name, { delete_existing_branch: true }, service_module_branch)
        git_subtrees_pull_on_to_sync_branch(aug_component_module_branches)
        RepoManager.merge_from_branch(sync_branch_name, { squash: true}, service_module_branch)
      end

      def git_subtrees_pull_on_to_sync_branch(aug_component_module_branches)
        add_remote_files_info = RepoManager::AddRemoteFilesInfo::GitSubtree.new
        aug_component_module_branches.each do |aug_component_mb|
          source_repo         = aug_component_mb.repo
          source_branch_name  = aug_component_mb.branch_name
          nested_module_dir   = Common.nested_module_dir(aug_component_mb.component_module)
          add_remote_files_info.add_git_subtree_info!(nested_module_dir, source_repo, source_branch_name) 
        end
        Generate::DirectoryGenerator.add_remote_files(add_remote_files_info, repo_dir: service_instance_repo_name, branch_name: sync_branch_name)
      end

      def git_subtrees_push_from_sync_branch(aug_component_module_branch)
        subtree_prefix = FileType::ServiceInstance::NestedModule.new(module_name: aug_component_module_branch.component_module_name).base_dir
        service_module_branch.push_subtree_to_component_module(subtree_prefix, aug_component_module_branch, source_branch_name: sync_branch_name) 
      end

      SYNC_BRANCH_PREFIX = 'git_subtree_sync'
      def sync_branch_name 
        "#{SYNC_BRANCH_PREFIX}_#{service_module_branch[:branch]}"
      end

      def service_instance_repo_name
        service_instance_repo.display_name
      end

      def service_instance_repo
        @service_instance_repo ||= get_service_instance_repo
      end
      def get_service_instance_repo
        if service_module_branch.respond_to?(:repo)
          # succeeds if service_module_branch is augmented branch; repo call more efficient than get_repo
          service_module_branch.repo
        else
          service_module_branch.get_repo
        end
      end

    end
  end
end

