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
  module CommonModule::DSL
    module Parse
      require_relative('parse/directory_parser')
      require_relative('parse/file_parser')

      def self.update_model_from_dsl(module_branch)
        ret = ModuleDSLInfo.new
        unless dsl_file_obj = DirectoryParser.matching_file_obj?(::DTK::DSL::FileType::CommonModule, branch: module_branch)
          fail Error, "Unexpected that 'dsl_file_obj' is nil"
        end
        ServiceModule.create_and_update_model_from_dsl(module_branch, dsl_file_obj)
        ComponentModule.update_model_from_dsl?(module_branch, dsl_file_obj)
        ret
      end

      module ServiceModule
        def self.update_model_from_dsl(module_branch, dsl_file_obj)
          update_component_module_refs(module_branch, dsl_file_obj)
        end

        private

        def update_component_module_refs(module_branch, dsl_file_obj)
          parsed_output = FileParser.parse_content(:common_module_depedencies, file_obj)
          pp [:debug, parsed_output]
        end
      end
      
      module ComponentModule
        # return if no component info
        def update_model_from_dsl?(module_branch, dsl_file_obj)
        end
      end

    end
  end
end
