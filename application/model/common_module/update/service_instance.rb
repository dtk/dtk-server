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
  class CommonModule
    class Update
      class ServiceInstance < self
        # Returns object of type CommonDSL::Diff::Result
        # opts can have keys
        #   :force_pull - Boolean (default false) 
        def self.update_from_repo(project, updated_nested_modules, commit_sha, service_instance, opts = {})
          diff_result = CommonDSL::Diff::Result.new
          module_branch = service_instance.base_module_branch
          unless module_branch.is_set_to_sha?(commit_sha)
            module_branch.pull_repo_changes_and_return_diffs_summary(commit_sha, force: opts[:force_pull]) do |repo_diffs_summary|
              unless repo_diffs_summary.empty?
                diff_result = CommonDSL::Diff::ServiceInstance.process(project, updated_nested_modules, commit_sha, service_instance, module_branch, repo_diffs_summary)
              end
              # This sets sha on branch only after all processing goes through
              module_branch.update_current_sha_from_repo!

              # update module_ref_sha for base service instance branch
              module_ref_shas = Assembly::Instance::ModuleRefSha.get_for_base_and_nested_modules(service_instance.assembly_instance)
              if base_module_ref_sha = module_ref_shas.find{ |mr_sha| mr_sha[:module_branch_id] == module_branch[:id] }
                base_module_ref_sha.update(sha: module_branch.get_field(:current_sha))
              end
            end
          end
          diff_result
        end

      end
    end
  end
end
