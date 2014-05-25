module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class DetectCreatedNodeIsReady < Top
        def consume(workitem)
          params = get_params(workitem) 
          PerformanceService.start(name(),object_id)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}

          user_object  = CurrentSession.new.user_object()

          execution_context(task,workitem,task_start) do
            callbacks = {
              :on_msg_received => proc do |msg|
                inspect_agent_response(msg)
                create_thread_in_callback_context(task,workitem,user_object) do
                  PerformanceService.end_measurement(name(),object_id)
                  
                  result = {:type => :completed_create_node, :task_id => task_id}
                  event = {:detected_node => {:senderid => msg[:senderid]}}
                  log_participant.end(:complete_succeed,event.merge(:task_id => task_id))
                  node = task[:executable_action][:node]
                  node.update_operational_status!(:running)
                  
                  #these must be called before get_and_propagate_dynamic_attributes
                  node.associate_elastic_ip?()
                  node.associate_persistent_dns?()
                  
                  action.get_and_propagate_dynamic_attributes(result,:non_null_attributes => ["host_addresses_ipv4"])
                  set_result_succeeded(workitem,result,task,action)
                  delete_task_info(workitem)
                  
                  reply_to_engine(workitem)
                end
              end,
              :on_timeout => proc do
                CreateThread.defer_with_session(user_object) do
                  result = {:type => :timeout_create_node, :task_id => task_id}
                  set_result_failed(workitem,result,task)
                  cancel_upstream_subtasks(workitem)
                  delete_task_info(workitem)
                  log_participant.end(:timeout,:task_id=>task_id)
                  reply_to_engine(workitem)
                end
              end
            }
            poll_to_detect_node_ready(workflow, action[:node], callbacks)
          end
        end

        def cancel(fei, flavour)
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          wi = workitem
          params = get_params(wi) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
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
