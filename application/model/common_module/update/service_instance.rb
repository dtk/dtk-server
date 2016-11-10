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
        #   :service_instance (required)
        #   :force_pull - Boolean (default false) 
        def self.update_from_repo(project, commit_sha, opts = {})
          diff_result = CommonDSL::Diff::Result.new
          unless service_instance = opts[:service_instance]
            fail Error, "opts[:service_instance] should not be nil"
          end
          module_branch = service_instance.get_service_instance_branch

          unless module_branch.is_set_to_sha?(commit_sha)
            repo_diffs_summary = module_branch.pull_repo_changes_and_return_diffs_summary(commit_sha, force: opts[:force_pull])
            if repo_diffs_summary
              diff_result = CommonDSL::Diff::ServiceInstance.process(service_instance, module_branch, repo_diffs_summary)
            end
            # This sets sha on branch only after all processing goes through
            module_branch.update_current_sha_from_repo!
          end
          diff_result
        end

      end
    end
  end
end
