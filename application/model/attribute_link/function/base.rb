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
module DTK; class AttributeLink
  class Function
    class Base < self
      def self.function_name?(function_def)
        function_def.is_a?(String) && function_def.to_sym
      end

      def self.base_link_function(input_attr, output_attr)
        input_type = attribute_index_type__input(input_attr)
        output_type = attribute_index_type__output(output_attr)
        unless ret = LinkFunctionMatrix[output_type][input_type]
          fail ErrorUsage, error_message_bad_link(input_attr, output_attr, input_type, output_type)
        end
        ret
      end
      # first index is output type, second one is input type
      # nil in column means not supported
      LinkFunctionMatrix = {
        scalar: {
          scalar: 'eq', indexed: 'eq_indexed', array: 'array_append'
        },
        indexed: {
          scalar: 'eq_indexed', indexed: 'eq_indexed', array: 'array_append'
        },
        array: {
          scalar: 'indexed_output', indexed: nil, array: 'eq'
        }
      }

      private

      def self.error_message_bad_link(input_attr, output_attr, input_type, output_type)
        input_attr_name = input_attr.get_field?(:display_name)
        output_attr_name = output_attr.get_field?(:display_name)
        "Not supported: Link that maps #{a_or_an(output_type)} attribute '#{output_attr_name}' to #{a_or_an(input_type)} attribute '#{input_attr_name}'"
      end
      def self.a_or_an(term)
        [:indexed, :array].include?(term.to_sym) ? "an #{term}" : "a #{term}"
      end

      def self.attribute_index_type__input(attr)
        # TODO: think may need to look at data type inside array
        if attr[:input_path] then :indexed
        else attr[:semantic_type_object].is_array?() ? :array : :scalar
        end
      end

      def self.attribute_index_type__output(attr)
        # TODO: may need to look at data type inside array
        if attr[:output_path] then :indexed
        else attr[:semantic_type_object].is_array?() ? :array : :scalar
        end
      end
    end
  end
end; end