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
  class ModuleDSL::V4::ObjectModelForm::ActionDef::Provider
    class Dynamic < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin
        Type = 'type'
      end
      
      # opts can have:
      #  :providers_input_hash: 
      #  :action_name: 
      #  :cmp_print_form
      def initialize(input_hash, opts = {})
        @input_hash           = input_hash
        @providers_input_hash = opts[:providers_input_hash] || {}
        @action_name          = opts[:action_name]
        @cmp_print_form       = opts[:cmp_print_form]
        # provider_specific_fields must be done after instance attributes set
        super(provider: type.to_s).merge!(provider_specific_fields)
      end

      def self.type
        :dynamic
      end

      def self.matches_input_hash?(input_hash)
        true
      end
      
      private

      def self.possible_type_keys
        [:ruby]
      end

      # TODO: DTK-2805: here treating provider attributes by preprocessing them and putting them in action def
      # To best handle incremental diffs might be easier to put provider attributes in object model and normalize dynamicaly
      def provider_specific_fields
        dynamic_type = dynamic_type()
        # so can compare provider_attributes and input hash attributes, normalize provider_attributes to symbol keys
        provider_attributes = (provider_attributes?(dynamic_type) || {}).inject({}) { |h, (k, v)| h.merge(k.to_sym => v) }
        keys_as_symbols = (provider_attributes.keys + @input_hash.keys).uniq
        keys_as_symbols.inject({}) do |h, k|
          # values in input_hash overwrite values in provider_attributes
          h.merge(k.to_s => @input_hash[k] || provider_attributes[k])
        end
      end
      
      def dynamic_type
        # TODO: put in dynmaic_type: right now need type field to be explicitly there
        Constant.matches?(@input_hash, :Type) || raise_error_no_type_key
      end

      def provider_attributes?(dynamic_type)
        @providers_input_hash[dynamic_type]
      end

      def raise_error_no_type_key
        fail ModuleDSL::ParsingError, "The definition for #{action_name_ref} on #{component_ref} is missing the '#{Constant::Type}' key"
      end
      
      def action_name_ref
        @action_name ? "action '#{@action_name}'" : "an action"
      end
      
      def component_ref
        @cmp_print_form ? "component '#{@cmp_print_form}'" : "the component"
      end
    end
  end
end

