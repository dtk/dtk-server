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
    module Parse
      class NestedModuleInfo
        require_relative('nested_module_info/impacted_file')

        attr_reader :module_name, :impacted_files 
        def initialize(service_module_branch, module_name, impacted_file_paths) 
          @service_module_branch = service_module_branch
          @module_name           = module_name
          @impacted_files        = impacted_file_paths.map { |path| ImpactedFile.new(self, path) }
        end
        private :initialize
        
        # returns array of Parse::NestedModule::Info objects or nil if none
        def self.impacted_modules_info?(service_module_branch, all_impacted_file_paths)
          ret = FileType::MatchingFiles.matching_files_array(FileType::ServiceInstance::NestedModule, all_impacted_file_paths).map do |dsl_matching_files_obj|
            new(service_module_branch, dsl_matching_files_obj.file_type_instance.module_name, dsl_matching_files_obj.file_paths)
          end
          ret.empty? ? nil : ret
        end
        
        def restrict_to_dsl_files?
          impacted_dsl_files = @impacted_files.select { |impacted_file| impacted_file.is_dsl_file? }
          unless impacted_dsl_files.empty?
            impacted_files = impacted_dsl_files.map { |impacted_file| ImpactedFile.new(self, impacted_file.path, is_dsl_file: true) } 
            self.class.new(@service_module_branch, @module_name, impacted_files)
          end
        end
        
        def impacted_file_paths
          @impacted_files.map { |impacted_file| impacted_file.path }
        end

        def top_nested_module_dsl_path
          @top_nested_module_dsl_path ||= DSL::FileType::ServiceInstance::NestedModule::DSLFile::Top.new(module_name: @module_name).canonical_path
        end
      end
    end
  end
end
