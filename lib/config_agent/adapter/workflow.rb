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
      def execute(task_info, opts = {})
        assembly_instance     = assembly_instance(opts[:task_idh], task_info) || fail(Error, "Unexepected that opts[:assembly] is nil")
        service_instance_name = assembly_instance.display_name
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
        component_workflow = component_workflow(component_template, method_name)
        component_workflow.bind_template_attributes!(formatted_attributes.merge content_params) if component_workflow.needs_template_substitution?

        task = Task::Create.create_for_workflow_action(assembly_instance, task_info, component_workflow)
        task = task.save_and_add_ids
        ruote_workflow = DTK::Workflow.create(task)
        ruote_workflow.execute_in_current_thread
        task_status_after_execution(ruote_workflow)
      end

      def initiate_cancelation(task_action, opts = {})
        fail(Error, "Unexpected that task id handle is nil") unless task_idh = opts[:task_idh]
        DTK::Workflow.cancel(task_action)
      end
      
      private 
      
      def task_status_after_execution(ruote_workflow)
        # updates subtasks to be what is current which wil be what is in database  (that is what update_object! does
        updated_subtasks = ruote_workflow.top_task[:subtasks].map {|subtask| subtask.update_object! }
        failed_subtasks = updated_subtasks.select { |subtask| subtask[:status] == 'failed' }
        # if no errors fine to return nil, otherwise need to return a task status hash or raise error
        fail ErrorUsage, generate_error_report(failed_subtasks) unless failed_subtasks.empty?
        nil
      end

      def generate_error_report(failed_subtasks)
        error_report = ""
        failed_subtasks.each do |failed_subtask|
          failed_tasks = failed_subtask.subtasks.select { |task| task[:status] == 'failed'}
          failed_tasks_errors = get_errors(failed_tasks)
          error_report += failed_tasks_errors + "\n" if failed_tasks_errors
        end
        error_report
      end

      def get_errors(failed_tasks)
        error_result = ""
        failed_tasks.each do |failed_task|
          error_msg = get_error_message(failed_task)
          if error_msg.key?(:content) && error_msg[:content].key?(:message)
            error_result += error_msg[:content][:message] + "\n"
          end
        end
        error_result
      end

      def get_error_message(failed_task)
        model_handle = failed_task.model_handle.createMH(:task_error)
        sp_hash = {
          cols: [:content],
          filter: [:eq, :task_id, failed_task.id]
        }
        Model.get_obj(failed_task.model_handle.createMH(:task_error), sp_hash)
      end

      def component_workflow(component_template, method_name)
        action_def_hash = ActionDef.get_matching_action_def_params?(component_template, method_name) || 
          fail(Error, "Unexpected that ActionDef.get_matching_action_def_params? is nil")
        subtasks =  (action_def_hash[:workflow] || {})[:subtasks] || fail(Error, "Unexpected action_def_hash[:workflow][:subtasks] is nil")
        ActionDef::Content::Command::Workflow.new(subtasks)
      end

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

      def assembly_instance(task_idh, task_info)
        assembly_id =
          if assembly_idh = task_info[:assembly_idh]
            if assembly_idh.is_a?(IDHandle) then assembly_idh.get_id()
            elsif assembly_idh.is_a?(Hash) then assembly_idh[:guid]
            end
          else
            # TODO: think this is reached for node group member; need to check if reached under any other condition
            if component_actions = task_info[:component_actions]
              if component = component_actions.first && component_actions.first[:component]
                component.get_field?(:assembly_id)
              end
            end
          end

        if assembly_id
          task_idh.createIDH(model_name: :assembly_instance, id: assembly_id).create_object()
        else
          Log.error("Could not find assembly id for task with id '#{task_idh.get_id()}'")
          nil
        end
      end

    end
  end
end; end
