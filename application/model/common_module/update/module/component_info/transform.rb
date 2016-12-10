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
  class CommonModule::Update::Module::ComponentInfo
    class Transform
      def initialize(parent)
        @dtk_dsl_info_processor = dtk_dsl_transform_helper(parent).info_processor(:component_info)
      end
      private :initialize

      def self.transform_to_component_module_form(parsed_common_module, parent)
        new(parent).transform_to_component_module_form(parsed_common_module)
      end

      def transform_to_component_module_form(parsed_common_module)
        parsed_common_module_string_keys = parsed_common_module.ret_hash_with_string_keys
        input_files_processor.add_hash_content!(common_module_top_dsl_path, parsed_common_module_string_keys)
        @dtk_dsl_info_processor.compute_outputs!
        pp [:transform_to_component_module_form, @dtk_dsl_info_processor]
      end

      private

      def dtk_dsl_transform_helper(parent)
        dtk_dsl_transform_class.new(parent.namespace_name, parent.module_name, parent.version)
      end

      def common_module_top_dsl_path
        self.class.common_module_top_dsl_path
      end
      def self.common_module_top_dsl_path
        @common_module_top_dsl_path ||= CommonDSL::FileType::CommonModule::DSLFile::Top.canonical_path
      end

      def input_files_processor
        @input_files_processor ||= input_files_processor_aux
      end

      def input_files_processor_aux
        type = :module
        @dtk_dsl_info_processor.indexed_input_files[type] || raise(Error, "Unexpected that no indexed_input_files of type '#{type}'")
      end

      def dtk_dsl_transform_class
        ::DTK::DSL::ServiceAndComponentInfo::TransformTo
      end
    end
  end
end
