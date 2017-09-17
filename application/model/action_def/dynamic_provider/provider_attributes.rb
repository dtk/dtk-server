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
  class ActionDef::DynamicProvider
    module ProviderAttributes
      ENTRYPOINT_ATTR_NAME  = 'entrypoint'
      DOMAIN_COMPONENT_NAME = 'provider'
      PROVIDER_NAMESPACE    = 'dtk-provider'
      module Mixin
        def set_provider_attributes!(provider_module_name, provider_attribute_values, assembly_instance)
          @ndx_provider_attributes = ProviderAttributes.ret_ndx_provider_attributes(provider_module_name, provider_attribute_values, assembly_instance)
        end
        
        def provider_attributes
          @ndx_provider_attributes.values
        end

        def entrypoint_attribute
          @ndx_provider_attributes[ProviderAttributes::ENTRYPOINT_ATTR_NAME] || raise_error_missing_action_def_param(ProviderAttributes::ENTRYPOINT_ATTR_NAME)
        end
        
        private
        
        def validate_provider_attributes
          ProviderAttributes.validate_provider_attributes(provider_attributes, self)
        end

      end

      def self.ret_ndx_provider_attributes(provider_module_name, provider_attribute_values, assembly_instance)
        domain_component = parameters_domain_component(provider_module_name, assembly_instance)
        domain_component.attributes_with_overrides(provider_attribute_values).inject({}) { |h, attr| h.merge(attr.display_name => attr) }
      end

      def self.validate_provider_attributes(provider_attributes, provider)
        missing_required_params = []
        provider_attributes.each do |attribute| 
          if attribute[:required] and attribute[:attribute_value].nil?
            missing_required_params << attribute.display_name
          end
        end
        
        unless missing_required_params.empty?
          err_msg  = "#{provider.action_ref_print_form} is missing required provider "
          if missing_required_params.size == 1 
            err_msg << "parameter '#{missing_required_params.first}'"
          else
            err_msg << "parameters: #{missing_required_params.join(', ')}"
          end
        end
      end
      
      private

      def self.parameters_domain_component(provider_module_name, assembly_instance)
        unless provider_component_module = matching_provider_component_module?(assembly_instance, provider_module_name)
          fail ErrorUsage, "Cannot find a dependent module in the service instance for provider '#{provider_module_name}'"
        end
        unless provider_component_template = provider_component_module.get_matching_component_template?(DOMAIN_COMPONENT_NAME)
          fail ErrorUsage, "Cannot find component '#{DOMAIN_COMPONENT_NAME}' in module '#{provider_module_name}'"
        end
        Component::Domain::Provider::Parameters.new(provider_component_template)
      end

      def self.matching_provider_component_module?(assembly_instance, provider_module_name)
        matching_component_modules = assembly_instance.get_component_modules(:recursive).select do |component_module|
          component_module.display_name == provider_module_name and
          component_module[:namespace_name] == PROVIDER_NAMESPACE
        end
        fail Error, "Unexpected that there is multiple matching component_modules" if matching_component_modules.size > 1
        matching_component_modules.first
      end

    end
  end
end


