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
# TODO: initially enterred through the simple dsl; may then put in model that uses db persistence, but caches this
module DTK
  class Attribute
    class SemanticDatatype
      require_relative('semantic_datatype/dsl_builder')
      require_relative('semantic_datatype/convert_from_string')

      extend SemanticDatatypeClassMixin
      include SemanticDatatypeMixin

      attr_reader :datatype
      def initialize(name)
        @name = name.to_s
        @datatype = nil
        @parent = nil
        @validation_proc = nil
      end
      # this must be placed here
      require_relative('semantic_datatype/asserted_datatypes')

      def self.default
        DefaultDatatype
      end
      DefaultDatatype = :string

      def self.convert_and_raise_error_if_not_valid(semantic_data_type, value, opts = {})
        if value.nil?
          return nil
        end
        unless is_valid?(semantic_data_type, value)
          if opts[:attribute_name]
            fail ErrorUsage.new("Attribute (#{opts[:attribute_name]}) has default value (#{value.inspect}) that does not match its type (#{semantic_data_type})")
          else
            fail ErrorUsage.new("The attribute value (#{value.inspect}) does not match its type (#{semantic_data_type})")
          end
        end
        convert_to_internal_form(semantic_data_type, value)
      end

      # called from Pattern class
      def self.raise_error_if_invalid_and_transform_if_needed(value, semantic_data_type, attribute_path)
        if value.kind_of?(::String)
          value = ConvertFromString.convert_if_non_scalar_type(value, semantic_data_type, attribute_path)
          unless is_valid?(semantic_data_type, value)
            fail ErrorUsage, "The provided value '#{value}' for '#{attribute_path}' is not of type #{semantic_data_type}" 
          end
        end
        value
      end

      def self.is_valid?(semantic_data_type, value)
        value.nil? || lookup(semantic_data_type).is_valid?(value)
      end

      def self.datatype(semantic_data_type)
        lookup(semantic_data_type).datatype
      end

      def is_valid?(value)
        @validation_proc.nil? || @validation_proc.call(value)
      end

      def self.isa?(term)
        all_types.key?(term.to_sym)
      end

      def self.convert_to_internal_form(semantic_data_type, value)
        if semantic_data_type
          lookup(semantic_data_type).convert_to_internal_form(value)
        else
          value
        end
      end
      def convert_to_internal_form(value)
        @internal_form_proc ? @internal_form_proc.call(value) : value
      end

      private

      def self.lookup(semantic_data_type)
        all_types[semantic_data_type.to_sym] || fail(ErrorUsage, "Illegal datatype (#{semantic_data_type})")
      end
    end
  end
end
