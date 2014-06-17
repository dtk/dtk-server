module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class SyncAgentCode < NodeParticipants

        def consume(workitem)
          params = get_params(workitem) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          PerformanceService.start(name(),object_id)          

          head_git_commit_id = nil
          # TODO Amar: test to remove dyn attrs and errors_in_result part
          execution_context(task,workitem,task_start) do

            node = task[:executable_action][:node]
            installed_agent_git_commit_id = node.get_field?(:agent_git_commit_id)
            head_git_commit_id = nil
            begin
              head_git_commit_id = AgentGritAdapter.get_head_git_commit_id()
              if R8::Config[:node_agent_git_clone][:mode] == 'debug'
                installed_agent_git_commit_id=node[:agent_git_commit_id]=nil
              end
             rescue => e
              Log.error("Error trying to get most recent sync agent code (#{e.to_s}); skipping the sync")
              head_git_commit_id = -1
            end
            if (head_git_commit_id == installed_agent_git_commit_id) or head_git_commit_id == -1
              set_result_succeeded(workitem,nil,task,action) if task_end
              if head_git_commit_id == -1
                log_participant.end(:skipped_because_of_error,:task_id=>task_id)
              else
                log_participant.end(:skipped_because_already_synced,:task_id=>task_id)
              end

              delete_task_info(workitem)
              PerformanceService.end_measurement(name(),object_id)
              return reply_to_engine(workitem)
            end

            user_object  = CurrentSession.new.user_object()

            callbacks = {
              :on_msg_received => proc do |msg|
                inspect_agent_response(msg)
                CreateThread.defer_with_session(user_object) do
                  # Amar: PERFORMANCE
                  PerformanceService.end_measurement(name(),object_id)
                  
                  result = msg[:body].merge("task_id" => task_id)
                  if result[:statuscode] != 0
                    event,errors = task.add_event_and_errors(:complete_failed,:config_agent,errors_in_result)
                    if event
                      log_participant.end(:complete_failed,:task_id=>task_id,:event => event, :errors => errors)
                    end
                    # Amar: SyncAgentCode will be skipped 99% of times, 
                    #       So for this subtask, we want to leave upstream tasks executing ignoring any errors
                    # cancel_upstream_subtasks(workitem)
                    set_result_failed(workitem,result,task)
                  else
                    node.update_agent_git_commit_id(head_git_commit_id)
                    task.add_event(:complete_succeeded,result)
                    log_participant.end(:complete_succeeded,:task_id=>task_id)
                    set_result_succeeded(workitem,result,task,action) if task_end 
                    action.get_and_propagate_dynamic_attributes(result)
                  end
                  # If there was a change on agents, wait for node's mcollective process to restart
                  unless R8::Config[:node_agent_git_clone][:no_delay_needed_on_server]
                    sleep(R8::Config[:node_agent_git_clone][:delay]||NodeAgentGitCloneDefaultDelay)
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
                  if event
                    log_participant.end(:timeout,:task_id=>task_id,:event => event, :errors => errors)
                  end
                  # cancel_upstream_subtasks(workitem)
                  set_result_timeout(workitem,result,task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              :on_cancel => proc do
                CreateThread.defer_with_session(user_object) do
                  log_participant.canceled(task_id)
                  set_result_canceled(workitem, task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end
            }
            receiver_context = {:callbacks => callbacks, :head_git_commit_id => head_git_commit_id, :expected_count => 1}
            begin
              workflow.initiate_sync_agent_action(task,receiver_context)
             rescue Exception => e
              e.backtrace
            end
          end
        end
        NodeAgentGitCloneDefaultDelay = 10

        # Ruote dispatch call to this method in case of user's cancel task request
        def cancel(fei, flavour)

          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour
          
          wi = workitem
          params = get_params(wi) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.add_internal_guards!(workflow.guards[:internal])
          log_participant.canceling(task_id)
          delete_task_info(wi)
          reply_to_engine(wi)
        end
      end
    end
  end
end
