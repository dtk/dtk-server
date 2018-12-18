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
        # Parses and processes anested module dsl changes; can update diff_result
        def self.process_nested_module_dsl_changes(diff_result, project, commit_sha, service_instance, aug_service_specific_mb, opts)
          # TODO: DTK-2727 use dtk-dsl library for parsing
          Legacy.parse_and_update_nested_module(aug_service_specific_mb, project, commit_sha, opts)
        end
        
        private

        module Legacy
          def self.parse_and_update_nested_module(aug_service_specific_mb, project, commit_sha, opts)
            component_module = aug_service_specific_mb.get_module
            impl_obj         = aug_service_specific_mb.get_implementation
            version          = aug_service_specific_mb.version
            
            aug_service_specific_mb.set_dsl_parsed!(false)
            module_name        = component_module.display_name
            namespace          = component_module.module_namespace
            initial_update     = false
            skip_missing_check = true
            force_parse        = true
            local_params       = ::DTK::ModuleBranch::Location::LocalParams::Server.new(module_type: component_module.module_type, module_name: module_name, version: version, namespace: namespace)
            opts.merge!(
              force_parse: force_parse,
              skip_missing_check: skip_missing_check,
              initial_update: initial_update
            )
            ::DTK::CommonModule::Update::NestedModule.update_from_repo(project, commit_sha, local_params, aug_service_specific_mb, opts)
            aug_service_specific_mb.set_dsl_parsed!(true)
          end

          private
          
          def self.is_parsing_error?(response)
            ModuleDSL::ParsingError.is_error?(response)
          end
        end
        
      end
    end
  end
end; end
