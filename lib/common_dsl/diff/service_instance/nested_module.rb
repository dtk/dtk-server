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
        def initialize(nested_module_name, impacted_files)
          @nested_module_name = nested_module_name
          @impacted_files     = impacted_files
        end
        private :initialize

        def self.process_nested_modules(diff_result, service_instance, module_branch, impacted_files)
          impacted_nested_modules(impacted_files).each do | nested_mdoule|
            nested_mdoule.process(diff_result, service_instance, module_branch)
          end
        end

        def process(diff_result, service_instance, module_branch)
          #TODO: stub
          pp [self.class, self]
        end
        

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
