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
    class ServiceModuleRepoSync
      class Transform
        # require_relative('transform/sync_branch')
        # require_relative('transform/service_instance')

        def self.transform_from_service_info(type, module_branch, aug_service_module_branch, dsl_file_path, opts = {} )
          if dtk_dsl_parse_helper = opts[:dtk_dsl_parse_helper]
            service_dsl_info_processor    = dtk_dsl_parse_helper.info_processor(:service_info)
            service_input_files_processor = service_dsl_info_processor.indexed_input_files[:assemblies]
            module_refs_input_files_processor = service_dsl_info_processor.indexed_input_files[:module_refs]

            files = RepoManager.ls_r(2, { file_only: true }, aug_service_module_branch)
            regexp = Regexp.new("assemblies/(.*)\.dtk\.assembly\.(yml|yaml)$")
            legacy_regexp = Regexp.new("assemblies/([^/]+)/assembly\.(yml|yaml)$")
            module_refs_regexp = Regexp.new("module_refs\.yaml$")

            assembly_files = files.select { |path| path =~ regexp }# regexp.match?(path) }
            legacy_files   = files.select { |path| path =~ legacy_regexp }#legacy_regexp.match?(path) }
            module_refs    = files.select { |path| path =~ module_refs_regexp }

            assembly_files.each do |path|
              file_content = aug_service_module_branch.get_raw_file_content(path)
              service_input_files_processor.add_content!(path, file_content)
            end

            module_refs.each do |path|
              file_content = aug_service_module_branch.get_raw_file_content(path)
              module_refs_input_files_processor.add_content!(path, file_content)
            end

            service_dsl_info_processor.compute_outputs!
          else
            nil
          end
        end

        # opts can have keys:
        #  :commit_msg
        def self.commit_all_changes(module_branch, opts = {})
          RepoManager.add_all_files_and_commit(opts, module_branch)
        end

        private

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
