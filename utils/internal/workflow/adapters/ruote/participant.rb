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
          params.merge!("task_end" => workitem.params["task_end"])
          params
        end

        def set_task_to_executing_and_ret_event(task)
          task.update_at_task_start()
        end
        def set_task_to_failed_preconditions(task,failed_antecedent_tasks)
          task.update_when_failed_preconditions(failed_antecedent_tasks)
        end
        def set_result_succeeded(workitem,new_result,task,action)
          task.update_at_task_completion("succeeded",TaskAction::Result::Succeeded.new())
          action.update_state_change_status(task.model_handle,:completed)  #this updates pending state
          set_result_succeeded__stack(workitem,new_result,task,action)
        end

        def set_result_failed(workitem,new_result,task,action)
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

         private
        #if use must coordinate with concurrence merge type
        def set_result_succeeded__stack(workitem,new_result,task,action)
          workitem.fields["result"] = {:action_completed => action.type}
        end
        def get_and_delete_task_info(workitem)
          params = workitem.params
          Ruote::TaskInfo.get_and_delete(params["task_id"],params["task_type"])
        end
      end

      class DetectCreatedNodeIsReady < Top
        def consume(workitem)
          params = get_params(workitem) 
          task_id,action,workflow,task = %w{task_id action workflow task}.map{|k|params[k]}
          callbacks = {
            :on_msg_received => proc do |msg|
              result = {:type => :completed_create_node, :task_id => task_id} 
              event = task.add_event(:complete_succeeded,result)
              pp [:found,msg[:senderid]]
              task[:executable_action][:node].update_operational_status!(:running)
              set_result_succeeded(workitem,result,task,action) 
              action.get_and_propagate_dynamic_attributes(result,:non_null_attributes => ["host_addresses_ipv4"])
              self.reply_to_engine(workitem)
            end,
            :on_timeout => proc do 
              Log.error("timeout detecting node is ready")
              result = {:type => :timeout_create_node, :task_id => task_id}
              set_result_failed(workitem,result,task,action)
              self.reply_to_engine(workitem)
            end
          }
          num_poll_cycles = 25
          poll_cycle = 6 #in seconds
          receiver_context = {:callbacks => callbacks, :expected_count => 1}
          opts = {:count => num_poll_cycles,:poll_cycle => poll_cycle}
          workflow.poll_to_detect_node_ready(action[:node],receiver_context,opts)
        end
      end

      class NodeParticpants < Top
        def execution_context(task,&body)
          debug_print_task_info = "task_id=#{task.id.to_s}"
          begin
            yield
          rescue CommandAndControl::Error => e
            task.update_at_task_completion("failed",TaskAction::Result::Failed.new(e))
            pp [:task_failed,debug_print_task_info,e]
            raise e
          rescue Exception => e
            task.update_at_task_completion("failed",TaskAction::Result::Failed.new(CommandAndControl::Error.new))
            pp [:task_failed_internal_error,debug_print_task_info,e,e.backtrace[0..15]]
            raise e
          end
        end
      end

      class AuthorizeNode < NodeParticpants
        def consume(workitem)
          params = get_params(workitem) 
          task_id,action,workflow,task = %w{task_id action workflow task}.map{|k|params[k]}
          execution_context(task) do
            callbacks = {
              :on_msg_received => proc do |msg|
                result = {:type => :authorized_node, :task_id => task_id} 
                event = task.add_event(:complete_succeeded,result)
                #task[:executable_action][:node].set_authorized()
                set_result_succeeded(workitem,result,task,action) 
                self.reply_to_engine(workitem)
              end,
              :on_timeout => proc do 
                result = {:type => :timeout_authorize_node, :task_id => task_id}
                set_result_failed(workitem,result,task,action)
                self.reply_to_engine(workitem)
              end
            }
            receiver_context = {:callbacks => callbacks, :expected_count => 1}
            workflow.initiate_executable_action(task,receiver_context)
          end
        end
      end

      class ExecuteOnNode < NodeParticpants
        #LockforDebug = Mutex.new
        def consume(workitem)
          #LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem) 
          task_id,action,workflow,task,task_end = %w{task_id action workflow task task_end}.map{|k|params[k]}
          task.update_input_attributes!()

          workitem.fields["guard_id"] = task_id # ${guard_id} is referenced if guard for execution of this

          failed_tasks = ret_failed_precondition_tasks(task,workflow.guards[:external])
          unless failed_tasks.empty?
            set_task_to_failed_preconditions(task,failed_tasks)
            #TODO: stub until
            pp ["precondition_failure", task_id] #TODO: stub
            return reply_to_engine(workitem)
          end

          task.add_internal_guards!(workflow.guards[:internal])
          event = set_task_to_executing_and_ret_event(task)

          pp ["executing #{action.class.to_s}",task_id,event] if event
          execution_context(task) do
            if action.long_running?
              callbacks = {
                :on_msg_received => proc do |msg|
                  result = msg[:body].merge("task_id" => task_id)
                  #result[:statuscode] is for transport errors and data is for errors for agent
                  succeeded = (result[:statuscode] == 0 and [:succeeded,:ok].include?((result[:data]||{})[:status]))
                  if succeeded
                    event = task.add_event(:complete_succeeded,result)
                    pp ["task_complete_succeeded #{action.class.to_s}", task_id,event] if event
                    set_result_succeeded(workitem,result,task,action) if task_end 
                    action.get_and_propagate_dynamic_attributes(result)
                  else
                    event,errors = task.add_event_and_errors(:complete_failed,result)
                    pp ["task_complete_failed #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                    set_result_failed(workitem,result,task,action)
                  end
                  reply_to_engine(workitem)
                end,
                :on_timeout => proc do 
                  result = {
                    "status" => "timeout" 
                  }
                  event,errors = task.add_event_and_errors(:complete_timeout,result)
                  pp ["task_complete_timeout #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                  set_result_timeout(workitem,result,task)
                  reply_to_engine(workitem)
                end
              }
              receiver_context = {:callbacks => callbacks, :expected_count => 1}
              workflow.initiate_executable_action(task,receiver_context)
            else
              result = workflow.process_executable_action(task)
              #TODO: this needs fixing up to be consisetnt with what resulst look like in async processing above
              if result[:status] == "failed"
                #TODO: looks like events and errors processing was oriented towards configure node so not putting following in yet
                event,errors = task.add_event_and_errors(:complete_failed,result)
                ##pp ["task_complete_failed #{action.class.to_s}", task_id,event,{:errors => errors}] if event
                ##set_result_failed(workitem,result,task,action)
                if result[:error_object]
                  #TODO: abort; there must be more graceful way to do this
                  raise ErrorUsage.new(result[:error_object].to_s)
                end
              else
                set_result_succeeded(workitem,result,task,action) if task_end 
              end
              reply_to_engine(workitem)
            end
          end
        end
       private
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
