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
      attr_reader :type

      def initialize(component_template, method_name, action_def_params, assembly_instance)
        @component_template      = component_template
        @method_name             = method_name
        # @component_template and @method_name need to be set first
        
        @action_def_params       = action_def_params
        @type                    = ret_type(action_def_params)
        @provider_module_name    = ret_provider_module_name(@type)
        @provider_parameter_info = ret_provider_parameter_info(@provider_module_name, assembly_instance) 
        @container_component     = ret_container_domain_component?(@provider_module_name, assembly_instance)
      end
      private :initialize
      
      def raise_error_if_not_valid
        validate_required_params
        self
      end
      
      def self.matching_dynamic_provider(component_template, method_name, assembly_instance)
        matching_dynamic_provider?(component_template, method_name, assembly_instance) ||
          fail(ErrorUsage, "Method '#{method_name}' not defined on component '#{component_template.display_name_print_form}'")
      end
      
      def self.matching_dynamic_provider?(component_template, method_name, assembly_instance)
        if action_def_params = ActionDef.get_matching_action_def_params?(component_template, method_name)
          new(component_template, method_name, action_def_params, assembly_instance)
        end
      end
      
      def entrypoint
        @action_def_params[:entrypoint] || raise_error_missing_action_def_param(:entrypoint)
      end
      
      def docker_file?
        if @docker_file_set
          @docker_file
        else
          @docker_file_set = true
          if dockerfile_template = (@container_component && @container_component.dockerfile_template?) 
            @docker_file = MustacheTemplate.render(dockerfile_template, action_def_params_with_defaults)
          end
        end
      end
      
      private
      
      def ret_type(action_def_params)
        action_def_params[:type] || raise_error_missing_action_def_param(:type)
      end
      
      def raise_error_missing_action_def_param(param_name)
        fail ErrorUsage, "#{action_ref_print_form} does not have the parameter '#{param_name}' defined"
      end

      PROVIDER_MODULE_DELIM = '-'
      
      def ret_provider_module_name(type)
        "#{type}#{PROVIDER_MODULE_DELIM}provider"
      end

      def validate_required_params
        missing_required_params = @provider_parameter_info.select { |info| info.required and ! @action_def_params.has_key?(info.name) }.map(&:name)
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

      def action_ref_print_form
        "Action method '#{@method_name}' on component '#{@component_template.display_name_print_form}'"
      end

      def action_def_params_with_defaults
        @action_def_params_with_defaults ||= compute_action_def_params_with_defaults
      end
      
      def compute_action_def_params_with_defaults
        ret = @action_def_params.dup
        @provider_parameter_info.each do |info|
          ret.merge!(info.name => info.default) if !ret.has_key?(info.name) and !info.default.nil?
        end
        ret
      end

      def ret_provider_parameter_info(provider_module_name, action_instance)
        parameters_domain_component(provider_module_name, action_instance).parameter_info
      end
      
      def ret_container_domain_component?(provider_module_name, assembly_instance)
        component_module_refs    = assembly_instance.component_module_refs
        container_component_type = container_component_type(provider_module_name)

        if container_dtk_component = assembly_instance.find_matching_aug_component_template?(container_component_type, component_module_refs) 
          Component::Domain::Provider::Container.new(container_dtk_component)
        end
      end

      def parameters_domain_component(provider_module_name, assembly_instance)
        component_module_refs      = assembly_instance.component_module_refs
        parameters_component_type = parameters_component_type(provider_module_name)

        if parameters_dtk_component = assembly_instance.find_matching_aug_component_template?(parameters_component_type, component_module_refs) 
          Component::Domain::Provider::Parameters.new(parameters_dtk_component)
        else
          fail ErrorUsage, "The provider module '#{provider_module_name}' is missing a parameters component '#{PARAMETERS_COMPONENT_NAME}'"
        end
      end

      CONTAINER_COMPONENT_NAME = 'container'
      def container_component_type(provider_module_name)
        Component.component_type_from_module_and_component(provider_module_name, CONTAINER_COMPONENT_NAME)
      end

      PARAMETERS_COMPONENT_NAME = 'provider'
      def parameters_component_type(provider_module_name)
        Component.component_type_from_module_and_component(provider_module_name, PARAMETERS_COMPONENT_NAME)
      end

    end
  end
end
