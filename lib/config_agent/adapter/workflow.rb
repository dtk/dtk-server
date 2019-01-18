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
module DTK; class ConfigAgent
  module Adapter
    class Workflow < ConfigAgent

      def ret_msg_content(task_info, opts = {})
        component_action      = task_info[:component_actions].first
        attributes            = component_action[:attributes] || {}
        formatted_attributes  = get_formatted_attributes(attributes)
        method_name           = component_action.method_name? || 'create'
        component             = component_action.component
        component_template    = component_template(component)
        action_def            = ActionDef.get_matching_action_def_params?(component_template, method_name)
        task_params           = task_info[:task_params] || {}
        content_params        = task_info[:content_params] || {}

        ConfigAgent.raise_error_on_illegal_task_params(component_action.attributes, action_def, task_params.merge!(content_params)) if task_params && action_def.key?(:parameter_defs)

        action_def = component_action.action_def(cols: [:content, :method_name], with_parameters: true)
        action_def.workflow.each do |workflow|
          workflow.bind_template_attributes!(formatted_attributes.merge content_params) if workflow.needs_template_substitution?
        end

      end

      private 

      def component_template(component)
        component.id_handle(id: component[:ancestor_id]).create_object
      end

      def get_formatted_attributes(attributes)
        ret = {}
        attributes.each do |attribute|
          if (display_name = attribute[:display_name]) && (value_asserted = attribute[:value_asserted]) && value_asserted.is_a?(String)
            ret[display_name.to_sym] = value_asserted
          end
        end
        ret
      end

    end
  end
end; end