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
    class Diff
      module ServiceInstance
        require_relative('service_instance/dsl')
        require_relative('service_instance/nested_module')
        
        # returns object of type Diff::Result or raises error
        def self.process(project, updated_nested_modules, commit_sha, service_instance, module_branch, repo_diffs_summary)
          # TODO: DTK-2665: look at more consistently eithr putting error messages on results
          # or throwing errors
          # also look at doing pinpointed violation chaecking leveraging violation code
          diff_result         = Result.new(repo_diffs_summary)
          impacted_files      = repo_diffs_summary.impacted_files
          current_module_refs = service_instance.aug_dependent_base_module_branches
          Model.Transaction do
            # Parses and processes any service instance dsl changes; can update diff_result
            diff_result.module_refs_to_delete = DSL.process_service_instance_dsl_changes(diff_result, service_instance, module_branch, impacted_files)
            unless diff_result.any_errors?
            # Processes the changes to the nested module content and dsl 
            #Log.error("TODO: DTK-3366: update NestedModule.process_nested_module_changes")
            NestedModule.process_partial_nested_module_changes(service_instance)
            if !updated_nested_modules.nil? && !updated_nested_modules.empty?
              NestedModule.process_nested_module_changes(diff_result, project, updated_nested_modules, commit_sha, service_instance, module_branch, impacted_files, current_module_refs: current_module_refs)
            end
            end
          end
          diff_result
        end
        
      end
    end
  end
end
