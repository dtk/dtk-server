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
    module ComponentModuleRepoSync
      require_relative('component_module_repo_sync/transform_from_component_module')

      def self.push_to_component_module(service_module_branch, aug_component_module_branch)
        subtree_prefix = FileType::ServiceInstance::NestedModule.new(module_name: aug_component_module_branch.component_module_name).base_dir
        service_module_branch.push_subtree_to_component_module(subtree_prefix, aug_component_module_branch) do 
          # TODO: transform_to_component_module_repo_form
        end
      end

      def self.pull_from_component_modules(service_module_branch, aug_component_module_branches)
        return if aug_component_module_branches.empty?
        git_subtree_pull_from_component_modules(service_module_branch, aug_component_module_branches)
        transform_from_component_module_form(service_module_branch, aug_component_module_branches)
        # TODO add commit and push
      end

      private

      def self.git_subtree_pull_from_component_modules(service_module_branch, aug_component_module_branches)
        add_remote_files_info = RepoManager::AddRemoteFilesInfo::GitSubtree.new
        aug_component_module_branches.each do |aug_component_mb|
          source_repo         = aug_component_mb.repo
          source_branch_name  = aug_component_mb.branch_name
          nested_module_dir   = nested_module_dir(aug_component_mb)
          add_remote_files_info.add_git_subtree_info!(nested_module_dir, source_repo, source_branch_name) 
        end
        Generate::DirectoryGenerator.add_remote_files(service_module_branch, add_remote_files_info)
      end

      def self.transform_from_component_module_form(service_module_branch, aug_component_module_branches)
        aug_component_module_branches.each do |aug_component_mb| 
          TransformFromComponentModule.new(service_module_branch, aug_component_mb).transform
        end
      end

      def self.nested_module_name(aug_component_module_branch)
        aug_component_module_branch.component_module_name
      end

      NestedModuleFileType = FileType::ServiceInstance::NestedModule
      def self.nested_module_dir(aug_component_module_branch)
        NestedModuleFileType.new(module_name: nested_module_name(aug_component_module_branch)).base_dir
      end
        
    end
  end
end

