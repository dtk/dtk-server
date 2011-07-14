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
          params.merge!("top_task_idh" => task_info["top_task_idh"])
          params
        end

        def set_result_succeeded(workitem,new_result,task,action)
          update_hash = {
            :status => "succeeded",
            :result => TaskAction::Result::Succeeded.new()
          }             
          task.update(update_hash)
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
          update_hash = {
            :status => "failed",
            :result => TaskAction::Result::Failed.new(error)
          }             
          task.update(update_hash)
        end

        def set_result_timeout(workitem,new_result,task)
          update_hash = {
            :status => "failed",
            :result => TaskAction::Result::Failed.new(CommandAndControl::Error::Timeout.new)
          }             
          task.update(update_hash)
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
          task_id,action,workflow,task,task_end = %w{task_id action workflow task task_end}.map{|k|params[k]}
          callbacks = {
            :on_msg_received => proc do |msg|
              pp [:found,msg[:senderid]]
              task[:executable_action][:node].update_operational_status!(:powered_on)
              result = {:type => :completed_create_node, :task_id => task_id} 
              set_result_succeeded(workitem,result,task,action)
              action.get_and_propagate_dynamic_attributes(result)
              self.reply_to_engine(workitem)
            end,
            :on_timeout => proc do 
              pp [:timeout]
              self.reply_to_engine(workitem)
            end
          }
          num_poll_cycles = 10
          poll_cycle = 6
          context = {:callbacks => callbacks, :expected_count => 1,:count => num_poll_cycles,:poll_cycle => poll_cycle} 
          workflow.poll_to_detect_node_ready(action[:node],context)
        end
      end

      class DetectIfNodeIsResponding < Top
        def consume(workitem)
          params = get_params(workitem) 
          action,task,workflow = %w{action task workflow}.map{|k|params[k]}
          callbacks = {
            :on_msg_received => proc do |msg|
              pp [:found,msg[:senderid]]
              task[:executable_action][:node].update_operational_status!(:powered_on)
              self.reply_to_engine(workitem)
            end,
            :on_timeout => proc do 
              pp [:timeout]
              self.reply_to_engine(workitem)
            end
          }
          poll_cycle = 2
          context = {:callbacks => callbacks, :expected_count => 1,:count => 1,:poll_cycle => poll_cycle} 
          workflow.poll_to_detect_node_ready(action[:node],context)
        end
      end
      class ExecuteOnNode < Top
        #LockforDebug = Mutex.new
        def consume(workitem)
          #LockforDebug.synchronize{pp [:in_consume, Thread.current, Thread.list];STDOUT.flush}
          params = get_params(workitem) 
          task_id,action,workflow,task = %w{task_id action workflow task}.map{|k|params[k]}
          pp ["executing config on node", task_id,action[:node]]
          workitem.fields["guard_id"] = task_id # ${guard_id} is referenced if guard for execution of this
          execution_context(task) do
            if action.long_running?
              callbacks = {
                :on_msg_received => proc do |msg|
                  result = msg[:body].merge("task_id" => task_id)
                  pp [:result,result]
                  #result[:statuscode] is for transport errors and data is for errors for agent
                  succeeded = (result[:statuscode] == 0 and [:succeeded,:ok].include?((result[:data]||{})[:status]))
                  if succeeded
#                    set_result_succeeded(workitem,result,task,action) 
                    action.get_and_propagate_dynamic_attributes(result)
                  else
                    set_result_failed(workitem,result,task,action)
                  end
                  self.reply_to_engine(workitem)
                end,
                :on_timeout => proc do 
                  result = {
                    "status" => "timeout" 
                  }
                  set_result_timeout(workitem,result,task)
                  self.reply_to_engine(workitem)
                end
              }
              receiver_context = {:callbacks => callbacks, :expected_count => 1}
              workflow.initiate_executable_action(task,receiver_context)
            else
              result = workflow.process_executable_action(task)
              #TODO: determien how or whether to set set on succeeded or failed
              set_result_succeeded(workitem,result,task,action) 
              reply_to_engine(workitem)
            end
          end
        end

        def execution_context(task,&body)
          debug_print_task_info = "task_id=#{task.id.to_s}"
          begin
            yield
          rescue CommandAndControl::Error => e
            update_hash = {
              :status => "failed",
              :result => TaskAction::Result::Failed.new(e)
            }
            task.update(update_hash)
            pp [:task_failed,debug_print_task_info,e]
            raise e
          rescue Exception => e
            update_hash = {
              :status => "failed",
              :result => TaskAction::Result::Failed.new(CommandAndControl::Error.new)
            }
            task.update(update_hash)
            pp [:task_failed_internal_error,debug_print_task_info,e,e.backtrace[0..7]]
            raise e
          end
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
          pp [workitem.fields,workitem.params]
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
