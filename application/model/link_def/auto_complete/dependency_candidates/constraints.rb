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
  class LinkDef::AutoComplete
    class DependencyCandidates
      module Constraints
        def self.match?(constraints_or_preferences, dep_component, base_component)
          constraints_or_preferences.each do |constraint|
            begin
              # using $SAFE = 4 to stop users from executing malicious code in lambda scripts
              evaluated_fn = proc do
                $SAFE = 4
                eval(constraint)
              end.call
              
              fail ErrorUsage, "Currently only lambda functions are supported!" unless evaluated_fn.is_a?(Proc) && evaluated_fn.lambda?

              attributes          = parse_constraint_attributes(evaluated_fn, dep_component, base_component)
              constraints_matched = evaluated_fn.call(*attributes)
              return false unless constraints_matched
            end
          end
          true
        end

        private

        def self.parse_constraint_attributes(evaluated_fn, dep_component, base_component)
          attributes = []
          lambda_params = evaluated_fn.parameters
          
          dep_component_attrs  = dep_component.get_component_with_attributes_unraveled({})
          base_component_attrs = base_component.get_component_with_attributes_unraveled({})
          
          lambda_params.each do |param|
            attributes << get_lambda_param_attribute_value(param[1].to_s, dep_component_attrs, base_component_attrs, '__')
          end
          
          attributes
        end

        def self.get_lambda_param_attribute_value(param, dep_component_attrs, base_component_attrs, delimiter)
          param_cmp, param_attr = param.split(delimiter)

          match_attr =
            if param_cmp.eql?(pretify_cmp_name(dep_component_attrs[:component_type]))
              dep_component_attrs[:attributes].find{ |attr| (attr[:root_display_name]||attr[:display_name]).eql?(param_attr) }
            elsif param_cmp.eql?('this')
              base_component_attrs[:attributes].find{ |attr| (attr[:root_display_name]||attr[:display_name]).eql?(param_attr) }
            else
              fail Error, "Invalid lambda param specification '#{param}'"
            end
          
          match_attr ? match_attr[:value_asserted] : nil
        end

        def self.pretify_cmp_name(cmp_name)
          cmp_name.gsub('__', '_')
        end
      end
    end
  end
end

=begin
# TOOD: might deprecate

        def self.get_matching_by_preferences(preferences_matching_cmps, matching_cmps)
          preferences_matching_cmps.delete_if{ |pref| pref.nil? }
          if matching_cmps.size > 1
            preferences_matching_cmps.each do |pref|
              return [pref] if matching_cmps.include?(pref)
            end
          else
            return [preferences_matching_cmps.first]
          end
        end
        

=end
