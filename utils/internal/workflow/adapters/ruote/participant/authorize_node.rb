module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class AuthorizeNode < NodeParticipants
        def consume(workitem)
          params = get_params(workitem)
          PerformanceService.start(name(), object_id)
          task_id, action, workflow, task, task_start, task_end = %w(task_id action workflow task task_start task_end).map { |k| params[k] }
          task.update_input_attributes!() if task_start

          user_object  = CurrentSession.new.user_object()

          execution_context(task, workitem, task_start) do
            node = task[:executable_action][:node]
            if node.git_authorized?()
              set_result_succeeded(workitem, nil, task, action) if task_end
              log_participant.end(:skipped_because_already_authorized, task_id: task_id)
              delete_task_info(workitem)
              PerformanceService.end_measurement(name(), object_id)
              return reply_to_engine(workitem)
            end

            callbacks = {
              on_msg_received: proc do |msg|
                inspect_agent_response(msg)
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  PerformanceService.end_measurement(name(), object_id)

                  result = msg[:body].merge('task_id' => task_id)
                  if errors = errors_in_result?(result)
                    event, errors = task.add_event_and_errors(:complete_failed, :agent_authorize_node, errors)
                    if event
                      log_participant.end(:complete_failed, task_id: task_id, event: event, errors: errors)
                    end
                    set_result_failed(workitem, result, task)
                  else
                    log_participant.end(:complete_succeeded, task_id: task_id)
                    node.set_git_authorized(true)
                    set_result_succeeded(workitem, result, task, action) if task_end
                  end
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              on_timeout: proc do
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  result = { type: :timeout_authorize_node, task_id: task_id }
                  cancel_upstream_subtasks(workitem)
                  set_result_failed(workitem, result, task)
                  delete_task_info(workitem)
                  log_participant.end(:timeout, task_id: task[:id])
                  reply_to_engine(workitem)
                end
              end,
              on_error: proc do |error_obj|
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  cancel_upstream_subtasks(workitem)
                  delete_task_info(workitem)
                  log_participant.end(:error, error_obj: error_obj, backtrace: error_obj.backtrace[0..7], task_id: task[:id])
                  reply_to_engine(workitem)
                end
              end
            }
            context = { expected_count: 1 }
            workflow.initiate_node_action(:authorize_node, action[:node], callbacks, context)
          end
        end

        def cancel(_fei, flavour)
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
      end
    end
  end
end
