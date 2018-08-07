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
  class ConfigAgent::Adapter::Component::Parse
    class AttributeMapping
      require_relative('attribute_mapping/value')
      def initialize(input_spec, base_component_attributes)
        @input_spec                = input_spec
        @base_component_attributes = base_component_attributes
      end
      private :initialize

      def self.attribute_mapping(input_spec, base_component_attributes)
        new(input_spec, base_component_attributes).attribute_mapping
      end

      def attribute_mapping
        self.input_spec.inject({}) do |h, (attribute_name, attribute_value_term)|
          value = Value.value(attribute_value_term, self.ndx_base_attributes)
          h.merge(attribute_name.to_s => value)
        end
      end

      protected

      attr_reader :input_spec, :base_component_attributes

      def ndx_base_attributes
        @ndx_base_attributes ||= self.base_component_attributes.inject({}) { |h, attribute| h.merge(attribute.display_name => attribute) }
      end

    end
  end
end
