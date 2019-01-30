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
            if (subtask[:actions] && action = subtask[:actions].first) ||
              (subtask[:components] && action = subtask[:components].first)
              inline_params = get_and_remove_inline_params!(action) || {}
              subtask_params = subtask[:parameters] || {}
              subtask_params.merge! Hash[inline_params.collect do |param|
                split = param.split('=')
                [split[0].to_sym, split[1]]
              end]
              if actions = (subtask[:actions] || subtask[:components])
                content_params.merge!({actions.first => subtask_params})
              end
            end
          end
          content_params
        end

        def self.get_matching_content_params(content_params, executable_action)
          return nil if executable_action[:component_actions].nil? || content_params_empty?(content_params)

          component_action = executable_action[:component_actions].first
          method_name, component_name = get_name_data(component_action)
          method_name = '.' + method_name if method_name

          formed_action_path = component_name + (method_name || '')

          content_params.each do |full_action_path, params|
            module_name, action_name = full_action_path.to_s.split('::')
            diff_array = Diff::LCS.diff(formed_action_path, full_action_path.to_s)
            return params if diff_array.size == 0 || (diff_array.first.size == 4 && diff_array.size == 1)
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

      end
  end
end