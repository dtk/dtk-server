module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class InstallAgent < Top
        def consume(workitem)
          params = get_params(workitem)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          execution_context(task,workitem,task_start) do
            user_object  = CurrentSession.new.user_object()
            callbacks = {
              :on_msg_received => proc do |msg|
                inspect_agent_response(msg)
                #              CreateThread.defer_with_session(user_object) do
                PerformanceService.end_measurement("#{self.class.to_s.split("::").last}", self.object_id)
                task.add_event(:complete_succeeded,result)
                log_participant.end(:complete_succeeded,:task_id=>task_id)
                set_result_succeeded(workitem,result,task,action) if task_end 
                delete_task_info(workitem)
                reply_to_engine(workitem)
                #              end
              end,
              :on_timeout => proc do
                raise Error.new("not implemented yet")
              end,
              :on_cancel => proc do 
                raise Error.new("not implemented yet")
              end
            }
            receiver_context = {:callbacks => callbacks, :expected_count => 1}
            workflow.initiate_executable_action(task,receiver_context)
          end
        end
      end
    end
  end
end
