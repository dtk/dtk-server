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
    module Generate
      module ServiceInstance
        def self.generate_canonical_form(service_instance, service_module_branch)
          ContentInput.generate_for_service_instance(service_instance, service_module_branch)
        end
        
        # opts can have keys:
        #  :aug_nested_module_branches
        def self.generate_dsl(service_instance, service_module_branch, opts = {})
          add_service_dsl_files(service_instance, service_module_branch)
          if aug_nested_module_branches = opts[:aug_nested_module_branches]
            #TODO: DTK-2686: took out before commited to master; add_nested_modules_dsl_files(aug_nested_module_branches, service_module_branch)
          end
          RepoManager.push_changes(service_module_branch)
        end
        
        private
        
        def self.add_service_dsl_files(service_instance, service_module_branch)
          # content_input is a dsl version independent canonical form that has all content needed to
          content_input = generate_canonical_form(service_instance, service_module_branch)
          yaml_text = FileGenerator.generate_yaml_text(:service_instance, content_input, service_module_branch.dsl_version)
          file_type__content_array = [{ file_type: FileType::ServiceInstance, content: yaml_text }]
          DirectoryGenerator.add_files(service_module_branch, file_type__content_array, donot_push_changes: true)
        end
        
        def self.add_nested_modules_dsl_files(aug_nested_module_branches, service_module_branch)
          return if aug_nested_module_branches.empty?
          
          add_remote_files_info = RepoManager::AddRemoteFilesInfo::GitSubtree.new
          aug_nested_module_branches.each do |aug_nested_module_branch|
            source_repo         = aug_nested_module_branch[:repo]
            source_branch_name  = aug_nested_module_branch[:branch]
            target_relative_dir = FileType::ServiceInstanceNestedModule.new(aug_nested_module_branch[:module_name]).base_dir
            add_remote_files_info.add_git_subtree_info!(target_relative_dir, source_repo, source_branch_name) 
          end
          DirectoryGenerator.add_remote_files(service_module_branch, add_remote_files_info)
        end
        
      end
    end
  end
end

