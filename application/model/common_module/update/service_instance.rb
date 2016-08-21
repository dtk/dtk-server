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
        # opts can have keys
        #   :service_instance (required)
        #   :force_pull - Boolean (default false) 
        def self.update_from_repo(project, commit_sha, opts = {})
          unless service_instance = opts[:service_instance]
            fail Error, "opts[:service_instance] should not be nil"
          end
          ret = ModuleDSLInfo.new
          module_branch = service_instance.get_service_instance_branch

          unless pull_was_needed = module_branch.pull_repo_changes?(commit_sha, opts[:force_pull])
            # for testing
            # return ret
          end
          parsed_service_module = dsl_file_obj_from_repo(module_branch).parse_content(:service_instance)
          existing = CommonDSL::Generate.generate_service_instance_canonical_form(service_instance, module_branch)
          pp [parsed_service_module.class, existing.class]
          existing.diff?(parsed_service_module)
          ret
        end

        private

        def self.dsl_file_obj_from_repo(module_branch)
          CommonDSL::Parse.matching_service_instance_file_obj?(module_branch) || fail(Error, "Unexpected that 'dsl_file_obj' is nil")
        end

      end
    end
  end
end
