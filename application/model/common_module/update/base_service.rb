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
      class BaseService < self
        def self.create_or_update_from_common_module(project, local_params, common_module__module_branch, parse_hash)
          module_branch = create_or_ret_module_branch(:service_module, project, local_params, common_module__module_branch)
          update_component_module_refs_from_parse_hash(module_branch, parse_hash)
          CommonModule::BaseService.update_assemblies_from_parse_hash(project, module_branch, parse_hash)
        end
        
        private

        def self.update_component_module_refs_from_parse_hash(module_branch, parse_hash)
          if dependent_modules = parse_hash[:dependent_modules]
            component_module_refs = ModuleRefs.get_component_module_refs(module_branch)

            cmp_modules_with_namespaces = dependent_modules.map do |dm|
              { display_name: dm[:module_name], namespace_name: dm[:namespace], version_info: dm[:version] }
            end

            component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
          end
        end
        
      end
    end
  end
end
