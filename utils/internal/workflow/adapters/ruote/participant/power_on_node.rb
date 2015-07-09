module DTK
  module WorkflowAdapter
    module RuoteParticipant
      class PowerOnNode < Top
        def consume(workitem)
          params = get_params(workitem)
          PerformanceService.start("#{self.class.to_s.split('::').last}", self.object_id)
          # task_id,action,workflow,task = %w{task_id action workflow task}.map{|k|params[k]}
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.update_input_attributes!() if task_start
          user_object  = ::DTK::CurrentSession.new.user_object()

          execution_context(task,workitem,task_start) do
            callbacks = {
              on_msg_received: proc do |msg|
                inspect_agent_response(msg)
                create_thread_in_callback_context(task,workitem,user_object) do
                  # Amar: PERFORMANCE
                  PerformanceService.end_measurement("#{self.class.to_s.split('::').last}", self.object_id)

                  result = {type: :power_on_node, task_id: task_id}
                  node = task[:executable_action][:node]
                  # TODO: should update_admin_op_status be set initially to running meaning want it to be running
                  node.update_operational_status!(:running)
                  node.update_admin_op_status!(:running)

                  # these must be called before get_and_propagate_dynamic_attributes
                  node.associate_elastic_ip?()
                  node.associate_persistent_dns?()

                  action.get_and_propagate_dynamic_attributes(result,non_null_attributes: ['host_addresses_ipv4'])
                  Log.info "Successfully started node with id '#{task[:executable_action][:node].instance_id}'"
                  set_result_succeeded(workitem,result,task,action)

                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              on_timeout: proc do
                DTK::CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
                  Log.error('Timeout detecting node is ready to be powered on!')
                  result = {type: :timeout_create_node, task_id: task_id}
                  set_result_failed(workitem,result,task)
                  cancel_upstream_subtasks(workitem)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end
            }
            poll_to_detect_node_ready(workflow, action[:node], callbacks)
          end
        end

        def cancel(_fei, flavour)
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          wi = workitem
          params = get_params(wi)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.add_internal_guards!(workflow.guards[:internal])
          pp ["Canceling task #{action.class}: #{task_id}"]
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end
      end
    end
  end
end
