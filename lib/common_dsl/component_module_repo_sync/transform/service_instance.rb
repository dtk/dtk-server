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
          nested_module_dsl_hash = ObjectLogic::NestedModule.generate_content_input(@service_module_branch, @aug_component_module_branch)
          nested_module_dsl_hash = convert_top_level_symbol_keys_to_strings(nested_module_dsl_hash) # Needed because skipping Generate
          yaml_text = DSL::YamlHelper.generate(nested_module_dsl_hash)
          file_path = Common.nested_module_top_dsl_path(nested_module_name)
          file_path__content_array = [{ path: file_path, content: yaml_text }]
          Generate::DirectoryGenerator.add_files(@service_module_branch, file_path__content_array, donot_push_changes: true, no_commit: true)
          delete_nested_module_file(component_module_dsl_filename)
          delete_nested_module_file(module_refs_filename)
        end
        
        def self.commit_all_changes_on_service_instance(service_module_branch)
          RepoManager.add_all_files_and_commit({ commit_msg: "Merging in nested modules" }, service_module_branch)
        end

        private
        
        def nested_module_dir           
          Common.nested_module_dir(nested_module_name)
        end
        
        def nested_module_name
          @aug_component_module_branch.component_module_name
        end
        
        def delete_nested_module_file(relative_path)
          RepoManager.delete_file?("#{nested_module_dir}/#{relative_path}", { no_commit: true }, @service_module_branch)
        end
        
        def convert_top_level_symbol_keys_to_strings(hash)
          hash.inject({}) { |h, (k, v)| h.merge(k.to_s => v) }
        end

      end
    end
  end
end; end
