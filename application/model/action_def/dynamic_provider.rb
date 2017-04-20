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
  class ActionDef
    class DynamicProvider
      require_relative('dynamic_provider/container')
      require_relative('dynamic_provider/bash')
      require_relative('dynamic_provider/provider_attributes')

      include Container::Mixin
      include Bash::Mixin
      include ProviderAttributes::Mixin

      attr_reader :type

      def initialize(component_template, method_name, provider_attribute_values, assembly_instance)
        @component_template   = component_template
        @method_name          = method_name
        # @component_template and @method_name need to be set first
        
        @type                 = ret_type(provider_attribute_values)
        @provider_module_name = ret_provider_module_name(@type)

        # provider attributes are an array of DTK::Attribute objects 
        set_provider_attributes!(@provider_module_name, provider_attribute_values, assembly_instance)
        set_container_component!(@provider_module_name, assembly_instance)
      end
      private :initialize
      
      def raise_error_if_not_valid
        validate_provider_attributes
        self
      end
      
      def self.matching_dynamic_provider(component_template, method_name, assembly_instance)
        matching_dynamic_provider?(component_template, method_name, assembly_instance) ||
          fail(ErrorUsage, "Method '#{method_name}' not defined on component '#{component_template.display_name_print_form}'")
      end
      
      def self.matching_dynamic_provider?(component_template, method_name, assembly_instance)
        if provider_attribute_values = ActionDef.get_matching_action_def_params?(component_template, method_name)
          new(component_template, method_name, provider_attribute_values, assembly_instance)
        end
      end

      def action_ref_print_form
        "Action method '#{@method_name}' on component '#{@component_template.display_name_print_form}'"
      end
      
      private

      def ret_type(provider_attribute_values)
        provider_attribute_values[:type] || raise_error_missing_action_def_param(:type)
      end

      PROVIDER_MODULE_DELIM = '-'
      def ret_provider_module_name(type)
        "#{type}#{PROVIDER_MODULE_DELIM}provider"
      end

      def raise_error_missing_action_def_param(param_name)
        fail ErrorUsage, "#{action_ref_print_form} does not have the parameter '#{param_name}' defined"
      end

    end
  end
end


