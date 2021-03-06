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
    class NestedModuleRepo
      class Transform
        require_relative('transform/sync_branch')

        def self.transform_from_component_info(type, module_branch, aug_component_module_branch, dsl_file_path, opts = {})
          dsl_hash = ObjectLogic::ComponentInfoModule.generate_content_input(type, module_branch, aug_component_module_branch)
          dsl_hash = convert_top_level_symbol_keys_to_strings(dsl_hash) # Needed because skipping Generate
          yaml_text = DSL::YamlHelper.generate(dsl_hash)
          file_path__content_array = [{ path: dsl_file_path, content: yaml_text }]

          if dtk_dsl_parse_helper = opts[:dont_create_file] && opts[:dtk_dsl_parse_helper]
            component_dsl_info_processor = dtk_dsl_parse_helper.info_processor(:component_info)
            component_input_files_processor = component_dsl_info_processor.indexed_input_files[:component_dsl_file]
            module_refs_input_files_processor = component_dsl_info_processor.indexed_input_files[:module_refs]

            file_content = aug_component_module_branch.get_raw_file_content(component_module_dsl_filename)
            component_input_files_processor.add_content!(component_module_dsl_filename, file_content)

            module_ref_file_content = aug_component_module_branch.get_raw_file_content(module_refs_filename)
            module_refs_input_files_processor.add_content!(module_refs_filename, module_ref_file_content)

            component_dsl_info_processor.compute_outputs!
          else
            Generate::DirectoryGenerator.add_files(module_branch, file_path__content_array, donot_push_changes: true, no_commit: true)
          end

          # delete files in component module form
          base_dir = File.dirname(dsl_file_path)
          ([component_module_dsl_filename, module_refs_filename]).each do |file_path|
            RepoManager.delete_file?("#{base_dir}/#{file_path}", { no_commit: true }, module_branch)
          end            
        end

        # opts can have keys:
        #  :commit_msg
        def self.commit_all_changes(module_branch, opts = {})
          RepoManager.add_all_files_and_commit(opts, module_branch)
        end

        private

        def self.convert_top_level_symbol_keys_to_strings(hash)
          hash.inject({}) { |h, (k, v)| h.merge(k.to_s => v) }
        end

        COMPONENT_MODULE_DSL_FILENAME = 'dtk.model.yaml'
        def component_module_dsl_filename
          self.class.component_module_dsl_filename
        end
        def self.component_module_dsl_filename
          COMPONENT_MODULE_DSL_FILENAME
        end

        def module_refs_filename
          self.class.module_refs_filename
        end
        def self.module_refs_filename
          @module_refs_filename ||= ModuleRefs.meta_filename_path
        end

      end
    end
  end
end
