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
      module Mixin
        def provider_attributes
          self.ndx_provider_attributes.values
        end

        def entrypoint_attribute
          self.ndx_provider_attributes[ProviderAttributes::ENTRYPOINT_ATTR_NAME] || raise_error_missing_action_def_param(ProviderAttributes::ENTRYPOINT_ATTR_NAME)
        end

        protected

        def ndx_provider_attributes 
          @ndx_provider_attributes ||= self.provider_parameters.attributes_with_overrides(provider_attribute_values).inject({}) { |h, attr| h.merge(attr.display_name => attr) }
        end
        
        def provider_parameters
          @provider_parameters ||= ret_provider_parameters
        end

        private

        PARAMETER_COMPONENT_NAME = 'provider'

        def ret_provider_parameters
          if provider_component_template = provider_component_module.get_matching_component_template?(PARAMETER_COMPONENT_NAME) 
            Component::Domain::Provider::Parameters.new(provider_component_template)
          else
            fail(ErrorUsage, "Cannot find component '#{PARAMETER_COMPONENT_NAME}' in module '#{provider_component_module.display_name}'")
          end
        end
        
        def validate_provider_attributes
          ProviderAttributes.validate_provider_attributes(provider_attributes, self)
        end
      end

      def self.validate_provider_attributes(provider_attributes, provider)
        missing_required_params = []
        provider_attributes.each do |attribute| 
          if attribute[:required] and attribute[:attribute_value].nil?
            missing_required_params << attribute.display_name
          end
        end
        
        unless missing_required_params.empty?
          err_msg  = "#{provider.action_ref_print_form} is missing required provider"
          if missing_required_params.size == 1 
            err_msg << "parameter '#{missing_required_params.first}'"
          else
            err_msg << "parameters: #{missing_required_params.join(', ')}"
          end
        end
      end

      private


    end
  end
end


