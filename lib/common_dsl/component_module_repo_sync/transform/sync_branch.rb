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
module DTK; module CommonDSL
  class ComponentModuleRepoSync
    class Transform
      class SyncBranch < self
        require_relative('sync_branch/syntatic_transform')

        def initialize(service_module_branch, sync_branch_name, nested_module_info)
          @service_module_branch = service_module_branch
          @sync_branch_name      = sync_branch_name
          @nested_module_info    = nested_module_info
        end
        private :initialize

        # The method update_and_transform_ updates the sync branch on service module with content on service_module_branch
        # and then transforms to component module form (from nested module form)
        def self.update_and_transform(service_module_branch, sync_branch_name, nested_module_info)
          new(service_module_branch, sync_branch_name, nested_module_info).update_and_transform
        end
        def update_and_transform
          # process by first doing a merge and then seeing if a dsl file was impacted and if so do the transform
          merge_service_instance_into_sync_branch
          if nested_module_dsl_info = @nested_module_info.restrict_to_dsl_files?
            transform_dsl_files_in_synch_branch(nested_module_dsl_info)
            commit_all_changes_on_sync_branch
          end
        end

        private

        def merge_service_instance_into_sync_branch
          RepoManager.merge_from_branch(service_instance_branch_name, sync_branch_repo_context)
        end

        def commit_all_changes_on_sync_branch
          RepoManager.add_all_files_and_commit({ commit_msg: "Synching with service instance changes" }, sync_branch_repo_context)
        end

        def transform_dsl_files_in_synch_branch(nested_module_dsl_info)
          # TODO: only treating case where this file is not split
          impacted_dsl_files = nested_module_dsl_info.impacted_files
          
          unless impacted_dsl_file = impacted_dsl_files.size == 1 && impacted_dsl_files.first
            fail Error, "Not handling nested dsl files broken into multiple files" if not_treating
          end

          component_module_dsl_text, module_ref_text = SyntaticTransform.transform(impacted_dsl_file)
          file_path__content_array = 
            [
             { path: component_module_dsl_path, content: component_module_dsl_text },
             { path: module_ref_path, content: module_ref_text }
            ]
          RepoManager.add_files(sync_branch_repo_context, file_path__content_array, donot_push_changes: true, no_commit: true)
          RepoManager.delete_file?(nested_module_top_dsl_path, sync_branch_repo_context)
        end

        def component_module_dsl_path
          "#{nested_module_dir}/#{component_module_dsl_filename}"
        end
        def module_ref_path
          "#{nested_module_dir}/#{module_refs_filename}"
        end

        def nested_module_dir           
          @nested_module_dir ||= Common.nested_module_dir(module_name)
        end

        def nested_module_top_dsl_path
          Common.nested_module_top_dsl_path(module_name)
        end

        def module_name
          @nested_module_info.module_name
        end

        def sync_branch_repo_context
          { repo_dir: repo_dir, branch: @sync_branch_name } 
        end

        def service_instance_repo_context
          { repo_dir: repo_dir, branch: service_instance_branch_name }
        end

        # returns [repo_dir, repo_branch]
        def service_instance_repo_and_branch
          @service_instance_repo_and_branch ||= @service_module_branch.repo_and_branch
        end
        def repo_dir
          service_instance_repo_and_branch[0]
        end
        def service_instance_branch_name
          service_instance_repo_and_branch[1]
        end

      end
    end
  end
end; end
