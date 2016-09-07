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
          ret = CommonDSL::Diff::Result.new
          unless service_instance = opts[:service_instance]
            fail Error, "opts[:service_instance] should not be nil"
          end
          module_branch = service_instance.get_service_instance_branch
          
          unless pull_was_needed = module_branch.pull_repo_changes?(commit_sha, opts[:force_pull])
            # TODO: removed for testing
            # return ret
          end

          CommonDSL::Diff.process_service_instance(service_instance, module_branch)
        end

      end
    end
  end
end
