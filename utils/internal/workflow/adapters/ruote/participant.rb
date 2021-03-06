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
# TODO: think want to replace some of the DTK::CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
# with  create_thread_in_callback_context(task,workitem)
# and also do teh same for non threaded callbacks to make sure that have proper bahvior if fail in callback (i.e., canceling task)
module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class Top
        include ::Ruote::LocalParticipant

        r8_nested_require('participant', 'create_node')
        r8_nested_require('participant', 'install_agent')
        r8_nested_require('participant', 'execute_smoketest')
        r8_nested_require('participant', 'detect_created_node_is_ready')
        r8_nested_require('participant', 'stomp_debug')
        r8_nested_require('participant', 'delete_from_database')
        r8_nested_require('participant', 'command_and_control_action')
        r8_nested_require('participant', 'cleanup')

        include StompDebug

        def initialize(opts = nil)
          @opts = opts
        end

        def get_params(workitem)
          task_info = get_task_info(workitem)
          params = { 'task_id' => workitem.params['task_id'] }
          workflow = task_info['workflow']
          params.merge!('workflow' => workflow)
          params.merge!('task' => task_info['task'])
          params.merge!('action' => task_info['action'])
          params.merge!('task_start' => workitem.params['task_start'])
          params.merge!('task_end' => workitem.params['task_end'])
          params
        end

        def set_task_to_executing(task)
          task.update_at_task_start()
        end

        def add_start_task_event?(_task)
          # can be overwritten
          nil
        end

        def set_task_to_failed_preconditions(task, failed_antecedent_tasks)
          task.update_when_failed_preconditions(failed_antecedent_tasks)
        end

        def name
          self.class.to_s.split('::').last
        end

        def log_participant
          LogParticipant.new(self)
        end
        class LogParticipant
          def initialize(participant)
            @name = participant.name()
          end

          def start(*args)
            log(['start_action:', name] + args)
          end

          def end(result_type, *args)
            log(['end_action:', name, result_type] + args)
          end

          def event(event, *args)
            log(['event', name, event: sanitize_event(event)] + args)
          end

          def canceling(task_id)
            log(['canceling', name, task_id: task_id])
          end

          def canceled(task_id)
            log(['canceled', name, task_id: task_id])
          end

          private

          attr_reader :name
          def log(*args)
            Log.info_pp(*args)
          end

          def sanitize_event(event)
            # if has list of components then remove attributes in case they have sensitive values
            ret = event
            if components = event[:components]
              sanitized_components = components.map do |r|
                # if r[:component_name]; removing everyting else, which is teh attribute values
                r[:component_name] ? r[:component_name] : r
              end
              ret = ret.merge(components: sanitized_components)
            end
            ret
          end
        end

        def set_result_succeeded(workitem, new_result, task, action)
          task.update_at_task_completion('succeeded', Task::Action::Result::Succeeded.new())
          action.update_state_change_status(task.model_handle, :completed)  #this updates pending state
          set_result_succeeded__stack(workitem, new_result, task, action)
        end

        def set_result_debugging(workitem, new_result, task, action)
          task.update_at_task_debugging('debugging', Task::Action::Result::Debugging.new())          
          action.update_state_change_status(task.model_handle, :completed)  #this updates pending state
          #set_result_succeeded__stack(workitem, new_result, task, action)
        end

        def set_result_canceled(_workitem, task)
          # Amar: (TODO: Find better solution)
          # Flag that will be checked inside mcollective.poll_to_detect_node_ready and will indicate detection to stop
          # Due to asyc calls, it was the only way I could figure out how to stop node detection task
          task[:executable_action][:node][:is_task_canceled] = true

          task.update_at_task_completion('cancelled', Task::Action::Result::Cancelled.new())
        end

        def set_result_failed(_workitem, new_result, task)
          # Amar: (TODO: Find better solution)
          # Flag that will be checked inside mcollective.poll_to_detect_node_ready and will indicate detection to stop
          # Due to asyc calls, it was the only way I could figure out how to stop node detection task
          task[:executable_action][:node][:is_task_failed] = true
          error =
            if not new_result[:statuscode] == 0
              CommandAndControl::Error::Communication.new
            else
              data = new_result[:data]
              if data && data[:status] == :failed && (data[:error] || {})[:formatted_exception]
                CommandAndControl::Error::FailedResponse.new(data[:error][:formatted_exception])
              else
                CommandAndControl::Error.new
              end
            end
          task.update_at_task_completion('failed', Task::Action::Result::Failed.new(error))
        end

        def set_result_timeout(_workitem, _new_result, task)
          task.update_at_task_completion('failed', Task::Action::Result::Failed.new(CommandAndControl::Error::Timeout.new))
        end

        protected

        def poll_to_detect_node_ready(workflow, node, callbacks)
          # num_poll_cycles => number of times we are going to poll given node
          # poll_cycles     => cycle of poll in seconds
          num_poll_cycles = 50
          poll_cycle = 6
          receiver_context = { callbacks: callbacks, expected_count: 1 }
          opts = { count: num_poll_cycles, poll_cycle: poll_cycle }
          workflow.poll_to_detect_node_ready(node, receiver_context, opts)
        end

        private

        def execution_context(task, workitem, task_start = nil, &body)
          if task_start
            set_task_to_executing(task)
          end
          log_participant.start(task_id: task[:id])
          if event = add_start_task_event?(task)
            log_participant.event(event, task_id: task[:id])
          end
          execution_context_block(task, workitem, &body)
        end

        def execution_context_block(task, workitem, &_body)
          yield
        rescue Exception => e
          if task_is_active?(workitem) #this needed because, for example there can be a pending polling task
            event, errors = task.add_event_and_errors(:complete_failed, :server, [{ message: e.to_s }])
            log_participant.end(:execution_context_trap, event: event, errors: errors, backtrace: e.backtrace)
            task.update_at_task_completion('failed', errors: errors)
            cancel_upstream_subtasks(workitem)
            delete_task_info(workitem)
          end
          reply_to_engine(workitem)
        end

        def create_thread_in_callback_context(task, workitem, user_object, &body)
          CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
            execution_context_block(task, workitem, &body)
          end
        end

        # if use must coordinate with concurrence merge type
        def set_result_succeeded__stack(workitem, _new_result, _task, action)
          workitem.fields['result'] = { action_completed: action.type }
        end

        def get_task_info(workitem)
          Ruote::TaskInfo.get(workitem)
        end

        def delete_task_info(workitem)
          Ruote::TaskInfo.delete(workitem)
        end

        def get_top_task_id(workitem)
          workitem.params['top_task_id']
        end

        def task_is_active?(workitem)
          Workflow.task_is_active?(get_top_task_id(workitem))
        end

        def cancel_upstream_subtasks(workitem)
          # begin-rescue block is required, as multiple concurrent subtasks can initiate this method and only first will do the canceling
          Workflow.kill(get_top_task_id(workitem))
         rescue Exception => e
          Log.error_pp(['exception when cancel_upstream_subtasks', e, e.backtrace[0..5]])
        end
      end

      class NodeParticipants < Top
        r8_nested_require('participant', 'authorize_node')
        r8_nested_require('participant', 'sync_agent_code')
        r8_nested_require('participant', 'execute_on_node')
        r8_nested_require('participant', 'power_on_node')

        private

        def errors_in_result?(result, action = nil)
          CommandAndControl.errors_in_node_action_result?(result, action)
        end
      end

      class DebugTask < Top
        def consume(workitem)
          count = 15
          pp "debug task sleep for #{s} seconds"
          @is_on = true
          while @is_on && count > 0
            sleep 1
            count -= 1
          end
          pp 'debug task finished'
          reply_to_engine(workitem)
        end

        def cancel(_fei, _flavour)
          pp 'cancel called on debug task'
          # TODO: shut off loop not working
          p @is_on
          @is_on = false
        end
      end
    end
  end
end