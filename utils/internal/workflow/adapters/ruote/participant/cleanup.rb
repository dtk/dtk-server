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
      class Cleanup < Top
        # LockforDebug = Mutex.new
        def consume(workitem)
          # LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem)
          task_id, action, workflow, task, task_start, task_end = %w(task_id action workflow task task_start task_end).map { |k| params[k] }
          execution_context(task, workitem, task_start) do
            result = workflow.process_executable_action(task)
            if errors_in_result = errors_in_result?(result)
              event, errors = task.add_event_and_errors(:initialize_failed, :cleanup, errors_in_result)
              if event
                log_participant.end(:initialize_failed, task_id: task_id, event: event, errors: errors)
              end
              cancel_upstream_subtasks(workitem)
              set_result_failed(workitem, result, task)
            else
              log_participant.end(:cleanup_succeeded, task_id: task_id)
              set_result_succeeded(workitem, result, task, action) if task_end
            end
            reply_to_engine(workitem)
          end
        end

        def cancel(_fei, flavour)
          # Don't execute cancel if ruote process is killed
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          wi = workitem
          params = get_params(wi)
          task_id, action, workflow, task, task_start, task_end = %w(task_id action workflow task task_start task_end).map { |k| params[k] }
          task.add_internal_guards!(workflow.guards[:internal])
          log_participant.canceling(task_id)
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end

        private

        def errors_in_result?(result)
          if result[:status] == 'failed'
            error_object = result[:error_object]
            type = result[:type]
            error = { message: error_object && error_object.to_s, type: type }.reject { |k,v| v.nil? }
            error.empty? ? [] : [error]
          end
        end

      end
    end
  end
end