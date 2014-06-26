module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class ExecuteOnNode < NodeParticipants
        # LockforDebug = Mutex.new
        def consume(workitem)
          # LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem) 
          PerformanceService.start("#{self.class.to_s.split("::").last}", self.object_id)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          
          task.update_input_attributes!() if task_start
          workitem.fields["guard_id"] = task_id # ${guard_id} is referenced if guard for execution of this

          failed_tasks = ret_failed_precondition_tasks(task,workflow.guards[:external])
          unless failed_tasks.empty?
            set_task_to_failed_preconditions(task,failed_tasks)
            # TODO: stub until
            pp ["precondition_failure", task_id] #TODO: stub
            delete_task_info(workitem)
            return reply_to_engine(workitem)
          end

          task.add_internal_guards!(workflow.guards[:internal])
          execution_context(task,workitem,task_start) do
            if action.long_running?

              user_object  = CurrentSession.new.user_object()

              callbacks = {
                :on_msg_received => proc do |msg|
                  inspect_agent_response(msg)
                  CreateThread.defer_with_session(user_object) do
                    # Amar: PERFORMANCE
                    PerformanceService.end_measurement("#{self.class.to_s.split("::").last}", self.object_id)
                    
                    result = msg[:body].merge("task_id" => task_id)
                    if errors_in_result = errors_in_result?(result)
                      event,errors = task.add_event_and_errors(:complete_failed,:config_agent,errors_in_result)
                      pp ["task_complete_failed #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                      cancel_upstream_subtasks(workitem)
                      set_result_failed(workitem,result,task)
                    else
                      event = task.add_event(:complete_succeeded,result)
                      pp ["task_complete_succeeded #{action.class.to_s}", task_id,event] if event
                      set_result_succeeded(workitem,result,task,action) if task_end 
                      action.get_and_propagate_dynamic_attributes(result)
                    end
                    delete_task_info(workitem)
                    reply_to_engine(workitem)
                  end
                end,
                :on_timeout => proc do
                  CreateThread.defer_with_session(user_object) do
                    result = {
                      :status => "timeout" 
                    }
                    event,errors = task.add_event_and_errors(:complete_timeout,:server,["timeout"])
                    pp ["task_complete_timeout #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                    cancel_upstream_subtasks(workitem)
                    set_result_timeout(workitem,result,task)
                    delete_task_info(workitem)
                    reply_to_engine(workitem)
                  end
                end,
                :on_cancel => proc do 
                  CreateThread.defer_with_session(user_object) do
                    pp ["task_complete_canceled #{action.class.to_s}", task_id]
                    set_result_canceled(workitem, task)
                    delete_task_info(workitem)
                    reply_to_engine(workitem)
                  end
                end
              }
              receiver_context = {:callbacks => callbacks, :expected_count => 1}
              workflow.initiate_executable_action(task,receiver_context)
            else
              raise Error.new("TODO: if reach need to implement config node that is not long running")
            end
          end
        end

        # Ruote dispatch call to this method in case of user's cancel task request
        def cancel(fei, flavour)

          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          begin
            wi = workitem
            params = get_params(wi) 
            task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
            task.add_internal_guards!(workflow.guards[:internal])
            pp ["Canceling task #{action.class.to_s}: #{task_id}"]
            callbacks = {
                :on_msg_received => proc do |msg|
                  inspect_agent_response(msg)
                  # set_result_canceled(wi, task)
                  # delete_task_info(wi)
                  # reply_to_engine(wi)
                end
            }
            receiver_context = {:callbacks => callbacks, :expected_count => 1}
            workflow.initiate_cancel_action(task,receiver_context)
          rescue Exception => e
            pp "Error in cancel ExecuteOnNode #{e}"
          end
        end

       private
        def add_start_task_event?(task)
          task.add_event(:start)
        end

        def ret_failed_precondition_tasks(task,external_guards)
          ret = Array.new
          guard_task_idhs = task.guarded_by(external_guards)
          return ret if guard_task_idhs.empty?
          sp_hash = {
            :cols => [:id,:status,:display_name],
            :filter => [:and, [:eq,:status,"failed"],[:oneof,:id,guard_task_idhs.map{|idh|idh.get_id}]]
          }
          Model.get_objs(task.model_handle,sp_hash)
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
