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
        def self.create_or_update_from_parsed_common_module(project, local_params, common_module__module_branch, parsed_common_module)
          module_branch = create_or_ret_module_branch(:service_module, project, local_params, common_module__module_branch)
          update_component_module_refs_from_parsed_common_module(module_branch, parsed_common_module)
          CommonModule::BaseService.update_assemblies_from_parsed_common_module(project, module_branch, parsed_common_module)
        end
        
        private

        def self.update_component_module_refs_from_parsed_common_module(module_branch, parsed_common_module)
          if dependent_modules = parsed_common_module.val(:DependentModules)
            component_module_refs = ModuleRefs.get_component_module_refs(module_branch)

            cmp_modules_with_namespaces = dependent_modules.map do |parsed_module_ref|
              { 
                display_name: parsed_module_ref.req(:ModuleName), 
                namespace_name: parsed_module_ref.req(:Namespace), 
                version_info: parsed_module_ref.val(:ModuleVersion) 
              }
            end

            component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
          end
        end
        
      end
    end
  end
end
