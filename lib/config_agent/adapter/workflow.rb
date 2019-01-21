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

      def execute(task_action)
        ret_msg_content(task_action)
        #We now have a task action that has templates substituted in its components
        #I suppose we should form the task hash here that will get executed
        # You want to first create a hirerachical task and then execute a workflow on it. If you trace executing a 
        # workflow you can trace at https://github.com/dtk/dtk-server/blob/master/application/model/assembly/instance.rb#L268
        # AT This is point where a hierarchical task is created from pulling in the workflow to execute.
        # On line 272 you see  task.save!() which is hack needed in this code base that faciliattes the next steps that 
        # transalate the hierarchical task to the workflow executable language (ruote in this case).
        # When we write a new workflow executor it wil have teh following high level functions 
        # 1) One translate the workflow into the "hierarchical task form"
        # 2) Map the hierarchical task form to the exact launguage that step 2 uses to step through teh workflow
        # 3) Write code that steps through a workflow and sipatches actions to teh excutors (see arch slides I just posted) abd
        #    collects rsults
        # For the new executor we might be able to to make teh datastructure for teh hierarchical task the exact same that can be 
        # used in step 3.
        # Back tio teh curernt code. The key thing to look at after following https://github.com/dtk/dtk-server/blob/master/application/model/assembly/instance.rb#L268
        # is the code that does part 2 and 3 above that starts at https://github.com/dtk/dtk-server/blob/master/application/model/assembly/instance.rb#L246
        # You wil see you descend into code that does
        # 
        #  278:     def execute_service_action(task_id, params)
        # => 279:       task_idh = id_handle().createIDH(id: task_id, model_name: :task)
        # 280:       task     = Task::Hierarchical.get_and_reify(task_idh, params)
        # 281:       workflow = Workflow.create(task)
        # 282:       workflow.defer_execution()
        # The task you get in step 280 is essntially teh same structure saved by instance.rb#L268
        # Line 281 creates the ruote datastructure (step 2)
        # Line 282 executes the workflow (step 3)
      end

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
