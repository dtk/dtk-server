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
        def initialize(module_name, impacted_files)
          @module_name    = module_name
          @impacted_files = impacted_files
        end
        private :initialize

        def self.process_nested_modules(diff_result, service_instance, service_module_branch, impacted_files)
          nested_modules = impacted_nested_modules(impacted_files)
          unless nested_modules.empty?
            ndx_aug_nested_module_branches = service_instance.aug_nested_module_branches.inject({}) { |h, r| h.merge(r[:module_name] => r) }
            nested_modules.each do | nested_module|
              unless aug_nested_module_branch = ndx_aug_nested_module_branches[nested_module.module_name]
                fail Error, "Unexpected that ndx_aug_nested_module_branches[#{nested_module.module_name}] is nil"
              end
              nested_module.process(diff_result, aug_nested_module_branch, service_module_branch)
            end
          end
          raise 'here'
        end

        def process(diff_result, aug_nested_module_branch, service_module_branch)
          pp [self.class, self, aug_nested_module_branch]
        end

        attr_reader :module_name

        private

        def self.impacted_nested_modules(impacted_files)
          Parse::NestedModule.matching_files_array(impacted_files).map do |nested_module_info| 
            new(nested_module_info.module_name, nested_module_info.impacted_files)
          end
        end

      end
    end
  end
end; end
