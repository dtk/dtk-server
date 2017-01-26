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
      class ServiceInstance < self
        def initialize(service_module_branch, aug_component_module_branch)
          @service_module_branch       = service_module_branch
          @aug_component_module_branch = aug_component_module_branch
        end
        private :initialize
        
        # The method transform_service_instance_nested_modules iterates over all the nested modules on the service instances
        # and converts from 'component module form' to 'nested module form'
        def self.transform_nested_modules(service_module_branch, aug_component_module_branches)
          aug_component_module_branches.each do |aug_component_mb| 
            new(service_module_branch, aug_component_mb).transform_nested_module 
          end
          commit_all_changes_on_service_instance(service_module_branch)
        end
        
        def transform_nested_module
          dsl_file_path = Common.nested_module_top_dsl_path(nested_module_name)
          self.class.transform_from_component_info(:nested_module, @service_module_branch, @aug_component_module_branch, dsl_file_path)
        end

        private

        def self.commit_all_changes_on_service_instance(service_module_branch)
          commit_all_changes(service_module_branch, commit_msg: 'Merging in nested modules')
        end

        def nested_module_name
          @aug_component_module_branch.component_module_name
        end
        
        def nested_module_dir           
          Common.nested_module_dir(nested_module_name)
        end
        
      end
    end
  end
end; end
