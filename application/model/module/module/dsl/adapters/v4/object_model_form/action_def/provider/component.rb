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
module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef; class Provider
    class Component < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        Method  = 'method'
        Inputs  = 'inputs'
        Outputs = 'outputs'
        Type    = 'type'
      end

      def initialize(input_hash, _opts = {})
        @input_hash = input_hash # must be done first
        super(provider: type.to_s).merge!(self.provider_specific_fields)
      end

      def self.type
        :component
      end
      
      KEYS_INDICATING_TYPE = [:Method, :Inputs, :Outputs]
      
      def self.matches_input_hash?(input_hash)
        if type_term = input_hash_type?(input_hash)
          !self.other_types.include?(type_term) and 
            (!!KEYS_INDICATING_TYPE.find { |k| Constant.matches?(input_hash, k) } or 
             component_type_form?(type_term) )
        end
      end

      def self.component_type_form?(type_term)
        if type_term.kind_of?(::String)
          terms = type_term.split('::')
          if terms.size <= 2
            !terms.find { |term| !(term =~ /^[a-zA-Z0-9\-_]+$/) } 
          end
        end
      end
      
      protected

      attr_reader :input_hash

      def provider_specific_fields
        { provider: 'component',
          type: self.component_type,
          method: self.method,
          inputs: self.inputs?,
          outputs: self.outputs?
        }
      end

      def component_type
        raise_error_if_ill_formed_component_type(value(:Type))
      end

      DEFAULT_METHOD = 'create'
      def method
        value?(:Method) || DEFAULT_METHOD
      end

      def inputs?
        Constant.matches?(self.input_hash, :Inputs)
      end

      def outputs?
        Constant.matches?(self.input_hash, :Outputs)
      end

      def self.other_types
        @other_types ||= (self.all_possible_type_keys - [:component]).map(&:to_s)
      end

      private

      def self.all_possible_type_keys
        PROVIDER_CLASSES.map { |klass| klass.possible_type_keys }.flatten(1)
      end

      def raise_error_if_ill_formed_component_type(type_term)
        unless self.class.component_type_form?(type_term)
          fail ModuleDSL::ParsingError, "Ill-formed form for 'type' key in action def: #{type_term}"
        end
        type_term
      end

      def self.input_hash_type?(input_hash)
        Constant.matches?(input_hash, :Type)
      end

      def value?(key_type)
        Constant.matches?(self.input_hash, key_type)
      end

      def value(key_type)
        value?(key_type) || fail(ModuleDSL::ParsingError, "Missing action def key '#{key_type}'")
      end

    end
  end; end
end; end; end; end
