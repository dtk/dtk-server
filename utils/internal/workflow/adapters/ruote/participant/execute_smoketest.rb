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
  module WorkflowAdapter
    module RuoteParticipant
      class ExecuteSmoketest < Top
        def consume(workitem)
          parent = nil
          params = get_params(workitem)
          task_id, action, workflow, task, task_start, task_end = %w(task_id action workflow task task_start task_end).map { |k| params[k] }
          execution_context(task, workitem, task_start) do
            user_object  = CurrentSession.new.user_object()
            callbacks = {
              on_msg_received: proc do |msg|
                if node = action[:node]
                  node.update(managed: true)
                end
                inspect_agent_response(msg)
                #CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                PerformanceService.end_measurement("#{self.class.to_s.split('::').last}", self.object_id)
                task.add_event(:complete_succeeded, msg)
                log_participant.end(:complete_succeeded, task_id: task_id)
                set_result_succeeded(workitem, msg, task, action) if task_end
                delete_task_info(workitem)
                reply_to_engine(workitem)
                #end
              end,
              on_timeout: proc do |_msg|
                result = { status: 'timeout' }

                event, errors = task.add_event_and_errors(:complete_timeout, :server, ['timeout'])
                pp ["task_complete_timeout #{action.class}", task_id, event, { errors: errors }] if event
                set_result_timeout(workitem, result, task)
                delete_task_info(workitem)
                log_participant.end(:timeout, task_id: task[:id])
                reply_to_engine(workitem)
              end,
              on_cancel: proc do |_msg|
                # event,errors = task.add_event_and_errors(:complete_timeout,:server,["timeout"])
                pp ["task_complete_canceled #{action.class}", task_id]
                # cancel_upstream_subtasks(workitem)
                set_result_canceled(workitem, task)
                delete_task_info(workitem)
                reply_to_engine(workitem)
              end
            }

            if subtasks = workflow.top_task[:subtasks]
              subtasks.each { |st| (parent = st if st[:id] == task[:task_id]) }
            end

            receiver_context = { callbacks: callbacks, expected_count: 1, parent: parent }
            workflow.initiate_executable_action(task, receiver_context)
          end
        end

        def cancel(_fei, flavour)
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour
          wi = workitem
          params = get_params(wi)
          task_id, action, workflow, task, task_start, task_end = %w(task_id action workflow task task_start task_end).map { |k| params[k] }
          log_participant.canceling(task_id)

          callbacks = {
            on_msg_received: proc do |msg|
              inspect_agent_response(msg)
              cancel_upstream_subtasks(wi)
              set_result_canceled(wi, task)
              delete_task_info(wi)
              reply_to_engine(wi)
            end
          }
          receiver_context = { callbacks: callbacks, expected_count: 1 }
          workflow.initiate_cancel_action(task, receiver_context)
        end
      end
    end
  end
end