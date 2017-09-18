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

      def initialize(component_template, method_name, provider_attribute_values, assembly_instance)
        @component_template        = component_template
        @method_name               = method_name
        @provider_attribute_values = provider_attribute_values 
        @assembly_instance         = assembly_instance 
      end
      private :initialize

      def type
        @type ||= ret_type(self.provider_attribute_values)
      end

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
        "Action method '#{self.method_name}' on component '#{self.component_template.display_name_print_form}'"
      end

      protected

      attr_reader :method_name, :component_template, :method_name, :provider_attribute_values, :assembly_instance 

      def provider_module_name 
        @provider_module_name ||= ret_provider_module_name(self.type)
      end

      def provider_component_module
        @provider_component_module ||= ret_provider_component_module
      end        

      private

      def ret_provider_component_module
        unless @provider_component_module = matching_provider_component_module?
          fail ErrorUsage, "Cannot find a dependent module in the service instance for provider '#{self.provider_module_name}'"
        end
        @provider_component_module
      end

      PROVIDER_NAMESPACE = 'dtk-provider'

      def matching_provider_component_module?
        matching_component_modules = self.assembly_instance.get_component_modules(:recursive).select do |component_module|
          component_module.display_name == self.provider_module_name and
            component_module[:namespace_name] == PROVIDER_NAMESPACE
        end
        fail Error, "Unexpected that there is multiple matching component_modules" if matching_component_modules.size > 1
        matching_component_modules.first
      end
      
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


