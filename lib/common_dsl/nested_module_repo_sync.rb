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
    # Methods to sync to and from the service instance repo to the nested module repos using git subtree operations
    module NestedModuleRepoSync
      require_relative('nested_module_repo_sync/component_module_transform')
      
      def self.push_to_nested_module(service_module_branch, aug_nested_module_branch)
        nested_module_name = aug_nested_module_branch.component_module_name
        subtree_prefix = FileType::ServiceInstance::NestedModule.new(module_name: nested_module_name).base_dir
        service_module_branch.push_subtree_to_nested_module(subtree_prefix, aug_nested_module_branch) do 
          # TODO: transform_to_component_module_repo_form
        end
      end

      def self.pull_from_nested_modules(service_module_branch, aug_nested_module_branches)
        return if aug_nested_module_branches.empty?
        add_remote_files_info = RepoManager::AddRemoteFilesInfo::GitSubtree.new
        aug_nested_module_branches.each do |aug_nested_module_branch|
          source_repo         = aug_nested_module_branch.repo
          source_branch_name  = aug_nested_module_branch.branch_name
          target_relative_dir = target_relative_dir(aug_nested_module_branch[:module_name])

          add_remote_files_info.add_git_subtree_info!(target_relative_dir, source_repo, source_branch_name) 
        end

        Generate::DirectoryGenerator.add_remote_files(service_module_branch, add_remote_files_info)

        ComponentModuleTransform.transform_from_component_module_form(service_module_branch, aug_nested_module_branches)
      end

      private
        

      def self.target_relative_dir(module_name)
        FileType::ServiceInstance::NestedModule.new(module_name: module_name).base_dir
      end
        
    end
  end
end

