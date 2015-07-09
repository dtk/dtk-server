module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class CreateNode < Top
        # LockforDebug = Mutex.new
        def consume(workitem)
          # LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          execution_context(task,workitem,task_start) do
            result = workflow.process_executable_action(task)
            if errors_in_result = errors_in_result?(result)
              event,errors = task.add_event_and_errors(:initialize_failed,:create_node,errors_in_result)
              if event
                log_participant.end(:initialize_failed,task_id: task_id,event: event, errors: errors)
              end
              cancel_upstream_subtasks(workitem)
              set_result_failed(workitem,result,task)
            else
              node = task[:executable_action][:node]
              node.update_operational_status!(:running)
              node.update_admin_op_status!(:running)
              log_participant.end(:initialize_succeeded,task_id: task_id)
              set_result_succeeded(workitem,result,task,action) if task_end
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
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.add_internal_guards!(workflow.guards[:internal])
          log_participant.canceling(task_id)
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end

        private

        def errors_in_result?(result)
          if result[:status] == 'failed'
            result[:error_object] ? [{message: result[:error_object].to_s}] : []
          end
        end
      end
    end
  end
end
