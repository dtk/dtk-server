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
      ENTRYPOINT_ATTR_NAME = 'entrypoint'
      DOMAIN_COMPONENT_NAME = 'provider'

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
          ProviderAttributes.validate_provider_attributes(provider_attributes)
        end

      end

      def self.ret_ndx_provider_attributes(provider_module_name, provider_attribute_values, assembly_instance)
        domain_component = parameters_domain_component(provider_module_name, assembly_instance)
        domain_component.attributes_with_overrides(provider_attribute_values).inject({}) { |h, attr| h.merge(attr.display_name => attr) }
      end

      def self.validate_provider_attributes(provider_attributes)
        missing_required_params = []
        provider_attributes.each do |attribute| 
          if attribute[:required] and attribute[:attribute_value].nil?
            missing_required_params << attribute.display_name
          end
        end
        
        unless missing_required_params.empty?
          err_msg  = "#{action_ref_print_form} is missing required provider "
          if missing_required_params.size == 1 
            err_msg << "parameter '#{missing_required_params.first}'"
          else
            err_msg << "parameters: #{missing_required_params.join(', ')}"
          end
          fail Error,  err_msg
        end
      end
      
      private

      def self.parameters_domain_component(provider_module_name, assembly_instance)
        component_module_refs      = assembly_instance.component_module_refs
        parameters_component_type = parameters_component_type(provider_module_name)
          
        if parameters_dtk_component = assembly_instance.find_matching_aug_component_template?(parameters_component_type, component_module_refs) 
          Component::Domain::Provider::Parameters.new(parameters_dtk_component)
        else
          fail ErrorUsage, "The provider module '#{provider_module_name}' is missing a parameters component '#{DOMAIN_COMPONENT_NAME}'"
        end
      end

      def self.parameters_component_type(provider_module_name)
        Component.component_type_from_module_and_component(provider_module_name, DOMAIN_COMPONENT_NAME)
      end
      
    end
  end
end


