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
  module CommonDSL
    module ComponentModuleRepoSync
      class TransformFromComponentModule
        def initialize(service_module_branch, aug_component_module_branch)
          @service_module_branch       = service_module_branch
          @aug_component_module_branch = aug_component_module_branch
        end

        def transform
          nested_module_dsl_hash = ObjectLogic::NestedModule.generate_content_input(@service_module_branch, @aug_component_module_branch)
          nested_module_dsl_hash = convert_top_level_symbol_keys_to_strings(nested_module_dsl_hash) # Needed because skipping Generate
          yaml_text = DSL::YamlHelper.generate(nested_module_dsl_hash)
          file_type__content_array = [{ file_type: NestedModuleFileType::DSLFile::Top.new(module_name: nested_module_name), content: yaml_text }]
          Generate::DirectoryGenerator.add_files(@service_module_branch, file_type__content_array, donot_push_changes: true)
          delete_nested_module_file(component_module_dsl_filename)
          delete_nested_module_file(ModuleRefs.meta_filename_path)
        end

        private

        COMPONENT_MODULE_DSL_FILENAME = 'dtk.model.yaml'
        def component_module_dsl_filename
          COMPONENT_MODULE_DSL_FILENAME
        end

        def nested_module_dir           
          ComponentModuleRepoSync.nested_module_dir(@aug_component_module_branch)
        end

        def nested_module_name
          ComponentModuleRepoSync.nested_module_name(@aug_component_module_branch)
        end

        def delete_nested_module_file(relative_path)
          RepoManager.delete_file?("#{nested_module_dir}/#{relative_path}", @service_module_branch)
        end

        def convert_top_level_symbol_keys_to_strings(hash)
          hash.inject({}) { |h, (k, v)| h.merge(k.to_s => v) }
        end

      end
    end
  end
end
