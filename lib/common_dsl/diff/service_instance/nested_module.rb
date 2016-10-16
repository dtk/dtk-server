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
  class Diff
    module ServiceInstance
      class NestedModule
        def initialize(nested_module_info, aug_nested_module_branch, service_instance, service_module_branch)
          @module_name              = nested_module_info.module_name
          @impacted_files           = nested_module_info.impacted_files
          @aug_nested_module_branch = aug_nested_module_branch
          @service_instance         = service_instance
          @service_module_branch = service_module_branch
        end
        private :initialize

        def self.process_nested_modules?(diff_result, service_instance, service_module_branch, impacted_files)
          if nested_modules_info = impacted_nested_modules_info?(impacted_files)
            process_nested_modules(diff_result, nested_modules_info, service_instance, service_module_branch)
          end
        end

        def process(diff_result)
          pp [self.class, { module_name: @module_name, impacted_files: @impacted_files }]
          assembly_module_branch = create_module_for_service_instance?
        end

        private

        def self.impacted_nested_modules_info?(impacted_files)
          Parse::NestedModule.matching_files_array(impacted_files)
        end

        def self.process_nested_modules(diff_result, nested_modules_info, service_instance, service_module_branch)
          ndx_aug_nested_module_branches = service_instance.aug_nested_module_branches(augment_with_component_modules: true).inject({}) { |h, r| h.merge(r[:module_name] => r) }
          nested_modules_info.each do |nested_module_info|
            module_name = nested_module_info.module_name
            unless aug_nested_module_branch = ndx_aug_nested_module_branches[module_name]
              fail Error, "Unexpected that ndx_aug_nested_module_branches[#{module_name}] is nil"
            end
            new(nested_module_info, aug_nested_module_branch, service_instance, service_module_branch).process(diff_result)
          end
          raise 'here'
        end

        def create_module_for_service_instance?
          @service_instance.create_nested_module?(component_module, base_version: base_version)
        end

        def component_module 
          @aug_nested_module_branch[:component_module]
        end

        def base_version
          @aug_nested_module_branch[:version]
        end
      end
    end
  end
end; end
