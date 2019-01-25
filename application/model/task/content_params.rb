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
  class Task
    class ContentParams

        def self.get_subtask_content_params!(subtasks)
          content_params = {}
          subtasks.each do |subtask|
            if subtask[:actions] && action = subtask[:actions].first
              inline_params = get_and_remove_inline_params!(action) || {}
              subtask_params = subtask[:parameters] || {}
              subtask_params.merge! Hash[inline_params.collect do |param|
                split = param.split('=')
                [split[0].to_sym, split[1]]
              end]
              content_params.merge!({subtask[:actions].first => subtask_params})
            end
          end
          content_params
        end

        def self.get_matching_content_params(content_params, executable_action)
          return nil if executable_action[:component_actions].nil? || content_params_empty?(content_params)

          component_action = executable_action[:component_actions].first
          method_name, component_name = get_name_data(component_action)

          content_params.each do |full_action_path, params|
            module_name, action_name = full_action_path.split('::') #module_name = action_params_test, action_name = base.ruby_.. || puppet_with_params
            return params if match_full_action_path?(method_name, component_name, module_name, action_name) ? params : nil
          end
          nil
        end

        private

        def self.content_params_empty?(content_params)
          content_params.each { |k, v| return false unless v.empty?() }
          true
        end

        def self.get_and_remove_inline_params!(action)
          if inline_params_match = action.match(/(.+)[" "](.+)/)
            inline_params = inline_params_match[2].split(',')
            action.sub!(/[" "](.+)/, '')
          end
          inline_params
        end

        def self.get_name_data(component_action)
          component_name = component_action[:component][:display_name]
          if action_method = component_action[:action_method]
            return [action_method[:method_name], component_name]
          end
          [nil, component_name]
        end

        def self.module_name_match?(split_result)
          split_result.empty?
        end

        def self.match_full_action_path?(method_name, component_name, module_name, action_name)
          mod_name, comp_name = component_name.split(module_name + '_') #component_name = action_param_test, comp_name = _base || _puppet_with_params
          if module_name_match? mod_name
            unless method_name
              #comp_name can be action_name if it's a component action
              return component_name_match?(comp_name, action_name) 
            else
              component_to_match, method_name_to_match = action_name.split('.')
              return component_name_match?(comp_name, component_to_match) && method_name_to_match.eql?(method_name)
            end
          end
        end

        def self.component_name_match?(component_name, action_name_to_match)
          component_name.split('_' + action_name_to_match).empty?()
        end
      end
  end
end