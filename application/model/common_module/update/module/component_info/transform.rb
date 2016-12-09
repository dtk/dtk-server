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
      def initialize(parsed_component_defs, parent)
        @parsed_component_defs  = parsed_component_defs
        @dtk_dsl_info_processor = dtk_dsl_transform_helper(parent).info_processor(:component_info)
      end
      private :initialize

      def self.transform_to_component_module_form(parsed_component_defs, parent)
        new(parsed_component_defs, parent).transform_to_component_module_form
      end

      def transform_to_component_module_form
        pp [:parsed_component_defs, @parsed_component_defs]
        pp [:indexed_input_files, @dtk_dsl_info_processor.indexed_input_files]
      end

      private

      def dtk_dsl_transform_helper(parent)
        dtk_dsl_transform_class.new(parent.namespace_name, parent.module_name, parent.version)
      end

      def dtk_dsl_transform_class
        ::DTK::DSL::ServiceAndComponentInfo::TransformTo
      end

    end
  end
end
