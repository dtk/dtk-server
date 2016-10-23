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
    class ServiceInstance::NestedModule
      module DSL
        def self.parse_nested_module_dsl?(diff_result, service_instance, aug_service_specific_mb, impacted_files)
          if dsl_file_hash = dsl_file_hash?(impacted_files)
            parse_nested_module_dsl(diff_result, dsl_file_hash, service_instance, aug_service_specific_mb)
          end
        end
        
        private
        
        def self.dsl_file_hash?(impacted_files)
          # TODO: stub
          pp ['impacted_files', impacted_files]
          {}
        end

        def self.parse_nested_module_dsl(diff_result, dsl_file_hash, service_instance, aug_service_specific_mb)
          # TODO: stub
          pp ['parse_nested_module_dsl', service_instance, aug_service_specific_mb]
        end

      end
    end
  end
end; end
