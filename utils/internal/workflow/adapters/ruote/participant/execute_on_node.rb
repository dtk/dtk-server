module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class ExecuteOnNode < NodeParticipants
        def consume(workitem)
          params = get_params(workitem)
          PerformanceService.start("#{self.class.to_s.split('::').last}", self.object_id)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          top_task = workflow.top_task
          task.update_input_attributes!() if task_start
          workitem.fields['guard_id'] = task_id # ${guard_id} is referenced if guard for execution of this

          failed_tasks = ret_failed_precondition_tasks(task,workflow.guards[:external])
          unless failed_tasks.empty?
            set_task_to_failed_preconditions(task,failed_tasks)
            log_participant.event('precondition_failure', task_id: task_id)
            delete_task_info(workitem)
            return reply_to_engine(workitem)
          end

          task.add_internal_guards!(workflow.guards[:internal])
          execution_context(task,workitem,task_start) do
            if action.assembly_wide_component?()
              result = workflow.process_executable_action(task)
              process_action_result!(workitem,action,result,task,task_id,task_end)
              delete_task_info(workitem)
              return reply_to_engine(workitem)
            end

            user_object  = CurrentSession.new.user_object()
            callbacks = {
              on_msg_received: proc do |msg|
                inspect_agent_response(msg)
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  PerformanceService.end_measurement("#{self.class.to_s.split('::').last}", self.object_id)

                  result = msg[:body].merge('task_id' => task_id)
                  if has_action_results?(task,result)
                    task.add_action_results(result,action)
                  end
                  process_action_result!(workitem,action,result,task,task_id,task_end)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              on_timeout: proc do
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  result = {
                    status: 'timeout'
                  }
                  event,errors = task.add_event_and_errors(:complete_timeout,:server,['timeout'])
                  if event
                    log_participant.end(:timeout,task_id: task_id,event: event, errors: errors)
                  end
                  cancel_upstream_subtasks(workitem)
                  set_result_timeout(workitem,result,task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              on_cancel: proc do
                CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  log_participant.canceled(task_id)
                  set_result_canceled(workitem, task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end
            }
            receiver_context = {callbacks: callbacks, expected_count: 1}
            workflow.initiate_executable_action(task,receiver_context)
          end
        end

        # Ruote dispatch call to this method in case of user's cancel task request
        def cancel(_fei, flavour)
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          begin
            wi = workitem
            params = get_params(wi)
            task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
            task.add_internal_guards!(workflow.guards[:internal])
            Log.info_pp(["Canceling task #{action.class}: #{task_id}"])
            callbacks = {
              on_msg_received: proc do |msg|
                inspect_agent_response(msg)
                # set_result_canceled(wi, task)
                # delete_task_info(wi)
                # reply_to_engine(wi)
              end
            }
            receiver_context = {callbacks: callbacks, expected_count: 1}
            workflow.initiate_cancel_action(task,receiver_context)
          rescue Exception => e
            Log.error("Error in cancel ExecuteOnNode #{e}")
          end
        end

        private

        def has_action_results?(task,_results)
          task[:executable_action].config_agent_type.to_sym == ConfigAgent::Type::Symbol.dtk_provider
        end

        def add_start_task_event?(task)
          task.add_event(:start)
        end

        def ret_failed_precondition_tasks(task,external_guards)
          ret = []
          guard_task_idhs = task.guarded_by(external_guards)
          return ret if guard_task_idhs.empty?
          sp_hash = {
            cols: [:id,:status,:display_name],
            filter: [:and, [:eq,:status,'failed'],[:oneof,:id,guard_task_idhs.map(&:get_id)]]
          }
          Model.get_objs(task.model_handle,sp_hash)
        end

        def process_action_result!(workitem,action,result,task,task_id,task_end)
          if errors_in_result = errors_in_result?(result,action)
            event,errors = task.add_event_and_errors(:complete_failed,:config_agent,errors_in_result)
            if event
              log_participant.end(:complete_failed,task_id: task_id,event: event, errors: errors)
            end
            cancel_upstream_subtasks(workitem)
            set_result_failed(workitem,result,task)
          else
            event = task.add_event(:complete_succeeded,result)
            log_participant.end(:complete_succeeded,task_id: task_id)
            set_result_succeeded(workitem,result,task,action) if task_end
            action.get_and_propagate_dynamic_attributes(result)
          end
        end

        # TODO: need to turn threading off for now because if dont can have two threads
        # eat ech others messages; may solve with existing mechism or go straight to
        # using stomp event machine
        # may even not be necessary to thread the consume since very fast
        # update: with change so taht subscriptions based on thread global; this may be no longer applicable
        def do_not_thread
          true
        end
      end
    end
  end
end
