#TODO: think want to replace some of the DTK::CreateThread.defer_with_session(user_object) do
#with  create_thread_in_callback_context(task,workitem) 
#and also do teh same for non threaded callbacks to make sure that have proper bahvior if fail in callback (i.e., canceling task)
module DTK 
  module WorkflowAdapter
    module RuoteParticipant
      class Top
        include ::Ruote::LocalParticipant

        DEBUG_AGENT_RESPONSE = false

        def initialize(opts=nil)
          @opts = opts
        end

        def get_params(workitem)
          task_info = get_task_info(workitem)
          params = {"task_id" => workitem.params["task_id"]}
          workflow = task_info["workflow"]
          params.merge!("workflow" => workflow)
          params.merge!("task" => task_info["task"])
          params.merge!("action" => task_info["action"])
          params.merge!("task_start" => workitem.params["task_start"])
          params.merge!("task_end" => workitem.params["task_end"])
          params
        end

        def set_task_to_executing(task)
          task.update_at_task_start()
        end
        def add_start_task_event?(task)
          #can be overwritten
          nil
        end

        def set_task_to_failed_preconditions(task,failed_antecedent_tasks)
          task.update_when_failed_preconditions(failed_antecedent_tasks)
        end

        def set_result_succeeded(workitem,new_result,task,action)
          task.update_at_task_completion("succeeded",Task::Action::Result::Succeeded.new())
          action.update_state_change_status(task.model_handle,:completed)  #this updates pending state
          set_result_succeeded__stack(workitem,new_result,task,action)
        end

        def set_result_canceled(workitem, task)
          # Amar: (TODO: Find better solution)
          # Flag that will be checked inside mcollective.poll_to_detect_node_ready and will indicate detection to stop
          # Due to asyc calls, it was the only way I could figure out how to stop node detection task
          task[:executable_action][:node][:is_task_canceled] = true

          task.update_at_task_completion("cancelled",Task::Action::Result::Cancelled.new())
        end

        def set_result_failed(workitem,new_result,task)

          # Amar: (TODO: Find better solution)
          # Flag that will be checked inside mcollective.poll_to_detect_node_ready and will indicate detection to stop
          # Due to asyc calls, it was the only way I could figure out how to stop node detection task
          task[:executable_action][:node][:is_task_failed] = true
          error = 
            if not new_result[:statuscode] == 0
              CommandAndControl::Error::Communication.new
            else
              data = new_result[:data]
              if data and data[:status] == :failed and (data[:error]||{})[:formatted_exception]
                CommandAndControl::Error::FailedResponse.new(data[:error][:formatted_exception])
              else
                CommandAndControl::Error.new 
              end
            end
          task.update_at_task_completion("failed",Task::Action::Result::Failed.new(error))
        end

        def set_result_timeout(workitem,new_result,task)
          task.update_at_task_completion("failed",Task::Action::Result::Failed.new(CommandAndControl::Error::Timeout.new))
        end

       protected

        def inspect_agent_response(msg)
          if DEBUG_AGENT_RESPONSE
            Log.info "START: Debugging response from Mcollective"
            Log.info_pp msg
            Log.info "END: Debugging response from Mcollective"
          end
        end

        def poll_to_detect_node_ready(workflow, node, callbacks)
          # num_poll_cycles => number of times we are going to poll given node
          # poll_cycles     => cycle of poll in seconds
          num_poll_cycles, poll_cycle = 50, 6
          receiver_context = {:callbacks => callbacks, :expected_count => 1}
          opts = {:count => num_poll_cycles,:poll_cycle => poll_cycle}
          workflow.poll_to_detect_node_ready(node,receiver_context,opts)
        end

       private
        def execution_context(task,workitem,task_start=nil,&body)
          if task_start
            set_task_to_executing(task)
          end
          Log.info_pp ["executing #{self.class.to_s}",task[:id]]
          if event = add_start_task_event?(task)
            Log.info_pp [:start_task_event, event]
          end
          execution_context_block(task,workitem,&body)
        end

        def execution_context_block(task,workitem,&body)
          begin
            yield
          rescue Exception => e
            event,errors = task.add_event_and_errors(:complete_failed,:server,[{:message => e.to_s}])
            if event and errors
              Log.info_pp ["task_complete_failed #{self.class.to_s}", task[:id],event,{:errors => errors}]
              Log.info_pp e.backtrace
            end
            task.update_at_task_completion("failed",{:errors => errors})
            reply_to_engine(workitem)
          end
        end

        def create_thread_in_callback_context(task,workitem,user_object,&body)
          CreateThread.defer_with_session(user_object) do
            execution_context_block(task,workitem,&body)
          end
        end

        #if use must coordinate with concurrence merge type
        def set_result_succeeded__stack(workitem,new_result,task,action)
          workitem.fields["result"] = {:action_completed => action.type}
        end
        def get_task_info(workitem)
          params = workitem.params
          Ruote::TaskInfo.get(params["task_id"],params["task_type"])
        end
        def delete_task_info(workitem)
          params = workitem.params
          Ruote::TaskInfo.delete(params["task_id"],params["task_type"])
        end
        def get_top_task_id(workitem)
          params = workitem.params
          Ruote::TaskInfo.get_top_task_id(params["task_id"])
        end
        def cancel_upstream_subtasks(workitem)
          # begin-rescue block is required, as multiple concurrent subtasks can initiate this method and only first will do the canceling
          begin
            # Killing task to prevent upstream subtasks' execution
            Workflow.kill(get_top_task_id(workitem))            
          rescue Exception => e   
          end
        end
      end

      class CreateNode < Top
        #LockforDebug = Mutex.new
        def consume(workitem)
          #LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          execution_context(task,workitem,task_start) do
            result = workflow.process_executable_action(task)
            if errors_in_result = errors_in_result?(result)
              event,errors = task.add_event_and_errors(:complete_failed,:create_node,errors_in_result)
              pp ["task_complete_failed #{action.class.to_s}", task_id,event,{:errors => errors}] if event
              cancel_upstream_subtasks(workitem)
              set_result_failed(workitem,result,task)
            else
              node = task[:executable_action][:node]
              node.update_operational_status!(:running)
              node.update_admin_op_status!(:running)
              set_result_succeeded(workitem,result,task,action) if task_end 
            end
            reply_to_engine(workitem)
          end
        end

        def cancel(fei, flavour)
          
          # Don't execute cancel if ruote process is killed
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          wi = workitem
          params = get_params(wi) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.add_internal_guards!(workflow.guards[:internal])
          pp ["Canceling task #{action.class.to_s}: #{task_id}"]
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end

       private
        def errors_in_result?(result)
          if result[:status] == "failed"
            result[:error_object] ? [{:message => result[:error_object].to_s}] : []
          end
        end    
      end

      class PowerOnNode < Top

        def consume(workitem)
          params = get_params(workitem) 
          PerformanceService.start("#{self.class.to_s.split("::").last}", self.object_id)
          # task_id,action,workflow,task = %w{task_id action workflow task}.map{|k|params[k]}
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.update_input_attributes!() if task_start
          user_object  = ::DTK::CurrentSession.new.user_object()

          execution_context(task,workitem,task_start) do
            callbacks = {
              :on_msg_received => proc do |msg|
                inspect_agent_response(msg)
                create_thread_in_callback_context(task,workitem,user_object) do
                  # Amar: PERFORMANCE
                  PerformanceService.end_measurement("#{self.class.to_s.split("::").last}", self.object_id)

                  result = {:type => :power_on_node, :task_id => task_id}
                  node = task[:executable_action][:node]
                  # TODO should update_admin_op_status be set initially to running meaning want it to be running
                  node.update_operational_status!(:running)
                  node.update_admin_op_status!(:running)

                  # these must be called before get_and_propagate_dynamic_attributes
                  node.associate_elastic_ip?()
                  node.associate_persistent_dns?()

                  action.get_and_propagate_dynamic_attributes(result,:non_null_attributes => ["host_addresses_ipv4"])
                  Log.info "Successfully started node with id '#{task[:executable_action][:node].instance_id}'"
                  set_result_succeeded(workitem,result,task,action)

                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              :on_timeout => proc do 
                DTK::CreateThread.defer_with_session(user_object) do
                  Log.error("Timeout detecting node is ready to be powered on!")
                  result = {:type => :timeout_create_node, :task_id => task_id}
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

        def cancel(fei, flavour)
          
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          wi = workitem
          params = get_params(wi) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.add_internal_guards!(workflow.guards[:internal])
          pp ["Canceling task #{action.class.to_s}: #{task_id}"]
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end
      end

      class DetectCreatedNodeIsReady < Top
        def consume(workitem)
          params = get_params(workitem) 
          PerformanceService.start("#{self.class.to_s.split("::").last}", self.object_id)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}

          user_object  = ::DTK::CurrentSession.new.user_object()

          execution_context(task,workitem,task_start) do
            callbacks = {
              :on_msg_received => proc do |msg|
                inspect_agent_response(msg)
                create_thread_in_callback_context(task,workitem,user_object) do
                  # Amar: PERFORMANCE
                  PerformanceService.end_measurement("#{self.class.to_s.split("::").last}", self.object_id)
                  
                  result = {:type => :completed_create_node, :task_id => task_id}
                  
                  
                  Log.info_pp [:found,msg[:senderid]]
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
                DTK::CreateThread.defer_with_session(user_object) do
                  Log.error("Timeout detecting if node is ready")
                  result = {:type => :timeout_create_node, :task_id => task_id}
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

        def cancel(fei, flavour)
          
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          wi = workitem
          params = get_params(wi) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.add_internal_guards!(workflow.guards[:internal])
          pp ["Canceling task #{action.class.to_s}: #{task_id}"]
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end
      end

      class NodeParticipants < Top
        private
        def errors_in_result?(result)
          #result[:statuscode] is for transport errors and data is for errors for agent
          if result[:statuscode] != 0
            ["transport_error"]
          else
            data = result[:data]||{}
            unless data[:status] == :succeeded
              data[:error] ? [data[:error]] : (data[:errors]||[])
            end
          end
        end
      end

      class AuthorizeNode < NodeParticipants
        def consume(workitem)
          #TODO succeed without sending node request if authorized already
          params = get_params(workitem) 
          PerformanceService.start("#{self.class.to_s.split("::").last}", self.object_id)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.update_input_attributes!() if task_start

          user_object  = ::DTK::CurrentSession.new.user_object()

          execution_context(task,workitem,task_start) do
            callbacks = {
              :on_msg_received => proc do |msg|
                inspect_agent_response(msg)
                DTK::CreateThread.defer_with_session(user_object) do
                  # Amar: PERFORMANCE
                  PerformanceService.end_measurement("#{self.class.to_s.split("::").last}", self.object_id)
                  
                  result = msg[:body].merge("task_id" => task_id)
                  if errors = errors_in_result?(result)
                    event,errors = task.add_event_and_errors(:complete_failed,:agent_authorize_node,errors)
                    pp ["task_complete_failed #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                    set_result_failed(workitem,result,task)
                  else
                    pp ["task_complete_succeeded #{action.class.to_s}"]
                    #task[:executable_action][:node].set_authorized()
                    set_result_succeeded(workitem,result,task,action) if task_end 
                  end
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              :on_timeout => proc do
                DTK::CreateThread.defer_with_session(user_object) do
                  result = {:type => :timeout_authorize_node, :task_id => task_id}
                  cancel_upstream_subtasks(workitem)
                  set_result_failed(workitem,result,task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              :on_error => proc do |error_obj|
                DTK::CreateThread.defer_with_session(user_object) do
                  cancel_upstream_subtasks(workitem)
                  delete_task_info(workitem)
                  pp [:on_error,error_obj,error_obj.backtrace[0..7],task[:id]]
                end
              end 
            }
            context = {:expected_count => 1}
            workflow.initiate_node_action(:authorize_node,action[:node],callbacks,context)
          end
        end

        def cancel(fei, flavour)
          
          # flavour will have 'kill' value if kill_process is invoked instead of cancel_process
          return if flavour

          wi = workitem
          params = get_params(wi) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.add_internal_guards!(workflow.guards[:internal])
          pp ["Canceling task #{action.class.to_s}: #{task_id}"]
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end
      end

      class SyncAgentCode < NodeParticipants

        def consume(workitem)
          params = get_params(workitem) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          
          PerformanceService.start("#{self.class.to_s.split("::").last}", self.object_id)

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
                Log.info("task_complete_skipped_because_of_error #{self.class.to_s}")
              else
                Log.info("task_complete_skipped_already_synced #{self.class.to_s}")
              end

              delete_task_info(workitem)
              # Amar: PERFORMANCE
              PerformanceService.end_measurement("#{self.class.to_s.split("::").last}", self.object_id)
              return reply_to_engine(workitem)
            end

            user_object  = ::DTK::CurrentSession.new.user_object()

            callbacks = {
              :on_msg_received => proc do |msg|
                inspect_agent_response(msg)
                DTK::CreateThread.defer_with_session(user_object) do
                  # Amar: PERFORMANCE
                  PerformanceService.end_measurement("#{self.class.to_s.split("::").last}", self.object_id)
                  
                  result = msg[:body].merge("task_id" => task_id)
                  if result[:statuscode] != 0
                    event,errors = task.add_event_and_errors(:complete_failed,:config_agent,errors_in_result)
                    pp ["task_complete_failed SyncAgentCode", task_id,event,{:errors => errors}] if event
                    # Amar: SyncAgentCode will be skipped 99% of times, 
                    #       So for this subtask, we want to leave upstream tasks executing ignoring any errors
                    #cancel_upstream_subtasks(workitem)
                    set_result_failed(workitem,result,task)
                  else
                    node.update_agent_git_commit_id(head_git_commit_id)
                    event = task.add_event(:complete_succeeded,result)
                    pp ["task_complete_succeeded SyncAgentCode", task_id,event] if event
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
                DTK::CreateThread.defer_with_session(user_object) do
                  result = {
                    :status => "timeout" 
                  }
                  event,errors = task.add_event_and_errors(:complete_timeout,:server,["timeout"])
                  pp ["task_complete_timeout #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                  #cancel_upstream_subtasks(workitem)
                  set_result_timeout(workitem,result,task)
                  delete_task_info(workitem)
                  reply_to_engine(workitem)
                end
              end,
              :on_cancel => proc do
                DTK::CreateThread.defer_with_session(user_object) do
                  pp ["task_complete_canceled #{action.class.to_s}", task_id]
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
          pp ["Canceling task #{action.class.to_s}: #{task_id}"]
          set_result_canceled(wi, task)
          delete_task_info(wi)
          reply_to_engine(wi)
        end

      end

      class ExecuteOnNode < NodeParticipants
        #LockforDebug = Mutex.new
        def consume(workitem)
          #LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem) 
          PerformanceService.start("#{self.class.to_s.split("::").last}", self.object_id)
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          
          task.update_input_attributes!() if task_start
          workitem.fields["guard_id"] = task_id # ${guard_id} is referenced if guard for execution of this

          failed_tasks = ret_failed_precondition_tasks(task,workflow.guards[:external])
          unless failed_tasks.empty?
            set_task_to_failed_preconditions(task,failed_tasks)
            #TODO: stub until
            pp ["precondition_failure", task_id] #TODO: stub
            delete_task_info(workitem)
            return reply_to_engine(workitem)
          end

          task.add_internal_guards!(workflow.guards[:internal])
          execution_context(task,workitem,task_start) do
            if action.long_running?

              user_object  = ::DTK::CurrentSession.new.user_object()

              callbacks = {
                :on_msg_received => proc do |msg|
                  inspect_agent_response(msg)
                  DTK::CreateThread.defer_with_session(user_object) do
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
                  DTK::CreateThread.defer_with_session(user_object) do
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
                  DTK::CreateThread.defer_with_session(user_object) do
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
                  #set_result_canceled(wi, task)
                  #delete_task_info(wi)
                  #reply_to_engine(wi)
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

        #TODO: need to turn threading off for now because if dont can have two threads 
        #eat ech others messages; may solve with existing mechism or go straight to
        #using stomp event machine
        #may even not be necessary to thread the consume since very fast
        #update: with change so taht subscriptions based on thread global; this may be no longer applicable
        def do_not_thread
          true
        end
      end

      class EndOfTask < Top
        def consume(workitem)
          #pp [workitem.fields,workitem.params]
          pp "EndOfTask"
          reply_to_engine(workitem)
        end

      end
      class DebugTask < Top
        def consume(workitem)
          count = 15
          pp "debug task sleep for #{s.to_s} seconds" 
          @is_on = true
          while @is_on and count > 0
            sleep 1
            count -= 1
          end
          pp "debug task finished"
          reply_to_engine(workitem)
        end
        def cancel(fei, flavour)
          pp "cancel called on debug task"
          #TODO: shut off loop not working
          p @is_on
          @is_on = false
        end
      end
    end
  end
end

