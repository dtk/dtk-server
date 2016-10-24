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
        attr_reader :module_name
        def initialize(module_name, impacted_file_paths) 
          @module_name    = module_name
          @impacted_files = impacted_file_paths.map { |path| ImpactedFile.new(path) }
        end
        private :initialize
        
        # returns array of Parse::NestedModule::Info objects or nil if none
        def self.impacted_modules_info?(all_impacted_file_paths)
          ret = FileType::MatchingFiles.matching_files_array(FileType::ServiceInstance::NestedModule, all_impacted_file_paths).map do |dsl_matching_files_obj|
            new(dsl_matching_files_obj.file_type_instance.module_name, dsl_matching_files_obj.file_paths)
          end
          ret.empty? ? nil : ret
        end
        
        def restrict_to_dsl_files?
          impacted_dsl_files = @impacted_files.select { |impacted_file| impacted_file.is_dsl_file? }
          unless impacted_dsl_files.empty?
            self.class.new(@module_name, impacted_dsl_files.map { |impacted_file| ImpactedFile.new(impacted_file.path, is_dsl_file: true) } )
          end
        end
        
        def impacted_file_paths
          @impacted_files.map { |impacted_file| impacted_file.path }
        end
        
        class ImpactedFile
          attr_reader :path
          # opts can have keys
          #  :is_dsl_file
          def initialize(path, opts = {})
            @path        = path
            @is_dsl_file = opts[:is_dsl_file] || ret_is_dsl_file?(path)
          end
          
          def is_dsl_file?
            @is_dsl_file
          end
          
          private
         
          def ret_is_dsl_file?(path)
            # TODO: DTK-2707  use dtk-dsl library
            !!(path =~ /dtk\.model\.yaml$/)
          end
          
        end
      end
    end
  end
end
