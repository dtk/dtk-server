module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        @task.update(:status => "executing")
        executable_action = @task[:executable_action]
        if executable_action
          process_executable_action(executable_action)
        elsif @task[:temporal_order].to_sym == :sequential
          process_sequential()
        elsif @task[:temporal_order].to_sym == :concurrent
          process_concurrent()
        end
      end
     private
      def initialize(task)
        @task = task
      end

      def update_task(hash)
        @task.update(hash)
      end

      def process_executable_action(executable_action)
        begin 
          result_hash = CommandAndControl.execute_task_action(executable_action,@task)
          update_hash = {
            :status => "succeeded",
            :result => TaskAction::Result::Succeeded.new(result_hash)
          }
          @task.update(update_hash)
          executable_action.update_state(:completed)  #this send pending changes' states
#deprecating          propagate_output_vars(result_hash)
          debug_pp [:task_succeeded,@task.id,result_hash]
          :succeeded              
        rescue CommandAndControl::Error => e
          update_hash = {
            :status => "failed",
            :result => TaskAction::Result::Failed.new(e)
          }
          @task.update(update_hash)
          debug_pp [:task_failed,@task.id,e]
          :failed
        rescue Exception => e
          update_hash = {
            :status => "failed",
            :result => TaskAction::Result::Failed.new(CommandAndControl::Error.new)
          }
          @task.update(update_hash)
          debug_pp [:task_failed_internal_error,@task.id,e,e.backtrace]
          :failed
        end
      end

      def process_sequential()
        status = :succeeded
        mark_as_not_reached = false
        @task.elements.each do |subtask|
          subtask_wf = Simple.new(subtask)
          if mark_as_not_reached
            subtask_wf.update_task(:status => "not_reached")
          else
            subtask_status = subtask_wf.execute() 
            #TODO: what to sent whole task status when failue but not @task[:action_on_failure] == "abort"
            if subtask_status == :failed 
              status = :failed
              mark_as_not_reached = true if  @task[:action_on_failure] == "abort"
            end
          end
        end
        @task.update(:status => status.to_s)
        status
      end

      def process_concurrent()
        status = :succeeded
        lock = Mutex.new
        #TODO: not killing concurrent subtasks if one failes
        threads = @task.elements.map do |subtask|
          Thread.new do 
            subtask_status = Simple.new(subtask).execute()
            lock.synchronize do
              status = :failed if subtask_status == :failed 
            end
          end
        end
        threads.each{|t| t.join}
        @task.update(:status => status.to_s)
        status
      end

      def propagate_output_vars(result_hash)
        #TODO: convert to using dynamic attributes
        @task.task_param_inputs.each do |param_link|
          unless param_link.output_task and param_link[:input_var_path] and param_link[:output_var_path]
            Log.error("skipping param link because missing param")
            next
          end
          val = param_link[:input_var_path].inject(result_hash){|r,key|r[key]||{}}
          pointer = param_link.output_task[:executable_action]
          output_path = param_link[:output_var_path].inject([]){|r,x| r << x} 
          last_key = output_path.pop
          output_path.each do |k|
            pointer[k] ||= Hash.new
            pointer = pointer[k]
          end
          pointer[last_key] = val
          @task.update(:executable_action => param_link.output_task[:executable_action])
        end
      end

      def debug_pp(x)
        @@debug_lock.synchronize{pp x}
      end
      @@debug_lock = Mutex.new
    end
  end
end
