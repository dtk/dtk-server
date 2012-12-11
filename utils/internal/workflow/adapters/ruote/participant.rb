module XYZ 
  module WorkflowAdapter
    module RuoteParticipant
      class Top
        include ::Ruote::LocalParticipant
        def initialize(opts=nil)
          @opts = opts
        end

        def get_params(workitem)
          task_info = get_and_delete_task_info(workitem)
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
          task.update_at_task_completion("succeeded",TaskAction::Result::Succeeded.new())
          action.update_state_change_status(task.model_handle,:completed)  #this updates pending state
          set_result_succeeded__stack(workitem,new_result,task,action)
        end

        def set_result_failed(workitem,new_result,task)
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
          task.update_at_task_completion("failed",TaskAction::Result::Failed.new(error))
        end

        def set_result_timeout(workitem,new_result,task)
          task.update_at_task_completion("failed",TaskAction::Result::Failed.new(CommandAndControl::Error::Timeout.new))
        end

       protected

        def poll_to_detect_node_ready(workflow, node, callbacks)
          # num_poll_cycles => number of times we are going to poll given node
          # poll_cycles     => cycle of poll in seconds
          num_poll_cycles, poll_cycle = 25, 6
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
  
          begin
            yield
           rescue Exception => e
            event,errors = task.add_event_and_errors(:complete_failed,:server,[{:message => e.to_s}])
            if event and errors
              Log.info_pp ["task_complete_failed #{self.class.to_s}", task[:id],event,{:errors => errors}]
            end
            task.update_at_task_completion("failed",{:errors => errors})
            reply_to_engine(workitem)
          end
        end

        #if use must coordinate with concurrence merge type
        def set_result_succeeded__stack(workitem,new_result,task,action)
          workitem.fields["result"] = {:action_completed => action.type}
        end
        def get_and_delete_task_info(workitem)
          params = workitem.params
          Ruote::TaskInfo.get_and_delete(params["task_id"],params["task_type"])
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
             set_result_failed(workitem,result,task)
            else
              set_result_succeeded(workitem,result,task,action) if task_end 
            end
            reply_to_engine(workitem)
          end
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
          task_id,action,workflow,task = %w{task_id action workflow task}.map{|k|params[k]}

          callbacks = {
            :on_msg_received => proc do |msg|
              result = {:type => :power_on_node, :task_id => task_id}
              node = task[:executable_action][:node]
              # TODO do both statuses at once
              node.update_operational_status!(:running)
              node.update_admin_op_status!(:running)
              node.associate_elastic_ip()
              set_result_succeeded(workitem,result,task,action)
              action.get_and_propagate_dynamic_attributes(result,:non_null_attributes => ["host_addresses_ipv4"])
              task[:executable_action][:node].associate_persistent_dns()
              Log.info "Successfully started node with id '#{task[:executable_action][:node].instance_id}'"
              reply_to_engine(workitem)
            end,
            :on_timeout => proc do 
              Log.error("Timeout detecting node is ready to be powered on!")
              result = {:type => :timeout_create_node, :task_id => task_id}
              set_result_failed(workitem,result,task)
              reply_to_engine(workitem)
            end
          }

          poll_to_detect_node_ready(workflow, action[:node], callbacks)
        end
      end

      class DetectCreatedNodeIsReady < Top
        def consume(workitem)
          params = get_params(workitem) 
          task_id,action,workflow,task = %w{task_id action workflow task}.map{|k|params[k]}
          callbacks = {
            :on_msg_received => proc do |msg|
              result = {:type => :completed_create_node, :task_id => task_id} 
 
              Log.info_pp [:found,msg[:senderid]]
              node = task[:executable_action][:node]
              node.update_operational_status!(:running)
              # assign elastic ip if present, this covers both cases when starting node or creating it
              node.associate_elastic_ip()
              set_result_succeeded(workitem,result,task,action)
              action.get_and_propagate_dynamic_attributes(result,:non_null_attributes => ["host_addresses_ipv4"])
              node.associate_persistent_dns()

              reply_to_engine(workitem)
            end,
            :on_timeout => proc do 
              Log.error("Timeout detecting if node is ready")
              result = {:type => :timeout_create_node, :task_id => task_id}
              set_result_failed(workitem,result,task)
              reply_to_engine(workitem)
            end
          }

          poll_to_detect_node_ready(workflow, action[:node], callbacks)
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
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.update_input_attributes!() if task_start

          execution_context(task,workitem,task_start) do
            callbacks = {
              :on_msg_received => proc do |msg|
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
                reply_to_engine(workitem)
              end,
              :on_timeout => proc do 
                result = {:type => :timeout_authorize_node, :task_id => task_id}
                set_result_failed(workitem,result,task)
                reply_to_engine(workitem)
              end,
              :on_error => proc do |error_obj|
                pp [:on_error,error_obj,error_obj.backtrace[0..7],task[:id]]
              end 
            }
            context = {:expected_count => 1}
            workflow.initiate_node_action(:authorize_node,action[:node],callbacks,context)
          end
        end
      end

      class ExecuteOnNode < NodeParticipants
        #LockforDebug = Mutex.new
        def consume(workitem)
          #LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem) 
          task_id,action,workflow,task,task_start,task_end = %w{task_id action workflow task task_start task_end}.map{|k|params[k]}
          task.update_input_attributes!() if task_start

          workitem.fields["guard_id"] = task_id # ${guard_id} is referenced if guard for execution of this

          failed_tasks = ret_failed_precondition_tasks(task,workflow.guards[:external])
          unless failed_tasks.empty?
            set_task_to_failed_preconditions(task,failed_tasks)
            #TODO: stub until
            pp ["precondition_failure", task_id] #TODO: stub
            return reply_to_engine(workitem)
          end

          task.add_internal_guards!(workflow.guards[:internal])
          execution_context(task,workitem,task_start) do
            if action.long_running?
              callbacks = {
                :on_msg_received => proc do |msg|
                  result = msg[:body].merge("task_id" => task_id)
                  if errors_in_result = errors_in_result?(result)
                    event,errors = task.add_event_and_errors(:complete_failed,:config_agent,errors_in_result)
                    pp ["task_complete_failed #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                    set_result_failed(workitem,result,task)
                  else
                    event = task.add_event(:complete_succeeded,result)
                    pp ["task_complete_succeeded #{action.class.to_s}", task_id,event] if event
                    set_result_succeeded(workitem,result,task,action) if task_end 
                    action.get_and_propagate_dynamic_attributes(result)
                  end
                  reply_to_engine(workitem)
                end,
                :on_timeout => proc do 
                  result = {
                    :status => "timeout" 
                  }
                  event,errors = task.add_event_and_errors(:complete_timeout,:server,["timeout"])
                  pp ["task_complete_timeout #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                  set_result_timeout(workitem,result,task)
                  reply_to_engine(workitem)
                end
              }
              receiver_context = {:callbacks => callbacks, :expected_count => 1}
              workflow.initiate_executable_action(task,receiver_context)
            else
              raise Error.new("TODO: if reach need to implement config node that is not long running")
            end
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

