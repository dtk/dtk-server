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
    class ParameterDefs

      class << self

        def parse(comp_attributes, param_defs, task_params)
          parse_dynamic_attributes(comp_attributes, param_defs) if comp_attributes
          parse_parameter_defs(param_defs, task_params) if task_params
        end

        def parse_parameter_defs(parameter_def, task_params)
          task_params.delete(:node) if task_params && task_params[:node]
          strict = parameter_def[:strict] ? parameter_def[:strict] : false
          parameters = parameter_def[:parameter] || parameter_def[:parameters]

          match_action_params_with_task_params parameters, task_params if parameters
          handle_strict_params parameters, task_params if strict
        end

        def parse_dynamic_attributes(attributes, parameter_def)
          parameters = parameter_def[:parameter] || parameter_def[:parameters]
          attributes.each do |attr|
            attr_name = attr[:display_name]
            if parameters.key? attr_name.to_sym
              parameter_hash = parameters[attr_name.to_sym]
              is_param_dynamic = parameter_hash.key?(:dynamic) ? parameter_hash[:dynamic] : false
              raise_dynamic_mismatch attr_name unless is_param_dynamic.eql? attr[:dynamic]
            end
          end
        end

        private

        def match_action_params_with_task_params(parameters, task_params)
          parameters.each do |key, val|
            if task_params.key?(key)

              raise_dynamic_parameter_assign(key) if val[:dynamic]

              # check if task_params value can be cast to expected type (parameter_type)
              param_type = validate_param_type(key, val[:type])
              value = Attribute::SemanticDatatype::ConvertFromString.convert_if_non_scalar_type(task_params[key], param_type, '')

              raise_type_mismatch(key, param_type) unless Attribute::SemanticDatatype.is_valid?(param_type, value)
            elsif !task_params.key?(key) && val.key?(:required) && val[:required]
              raise_parameter_required key
            end
          end
        end

        def validate_param_type(param_name, param_type)
          return param_type if param_type == 'boolean'

          raise ErrorUsage, "Type #{param_type} for parameter '#{param_name}' is not valid" unless Module.constants.include? param_type.capitalize.to_sym
          param_type
        end

        def isBoolean?(value)
          return value == "true" || value == "false"
          false
        end

        def handle_strict_params(parameters, task_params)
          task_params.each do |key, value|
            raise_strict key unless parameters.key?(key)
          end
        end

        def raise_strict(attribute)
          raise ErrorUsage, "Strict type checking is set in the action parameters and command line parameter '#{attribute}' is not defined"
        end

        def raise_type_mismatch(parameter, expected)
          raise ErrorUsage, "Type mismatch for parameter '#{parameter}'. Expected #{expected}"
        end

        def raise_parameter_required(parameter)
          raise ErrorUsage, "Parameter '#{parameter}' is not set"
        end

        def raise_dynamic_mismatch(parameter)
          raise ErrorUsage, "Dynamic property mismatch for parameter '#{parameter}'"
        end

        def raise_dynamic_parameter_assign(parameter)
          raise ErrorUsage, "Cannot assign value to dynamic parameter '#{parameter}'"
        end
      end

    end
  end
end