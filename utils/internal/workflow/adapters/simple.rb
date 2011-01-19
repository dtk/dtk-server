module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        @task.update(:status => "executing")
        executable_action = @task[:executable_action]
        if executable_action
          process_executable_action(executable_action)
        elsif @task[:temporal_order] == "sequential"
          process_sequential()
        elsif @task[:temporal_order] == "concurrent"
          process_concurrent()
        else
          Log.error("do not have rules to process task")
        end
      end

      def update_task(hash)
        @task.update(hash)
      end

     private
      def initialize(task)
        @task = task
      end

      def process_executable_action(executable_action)
        begin 
          result_hash = CommandAndControl.execute_task_action(executable_action,@task)
          update_hash = {
            :status => "succeeded",
            :result => TaskAction::Result::Succeeded.new(result_hash)
          }
          @task.update(update_hash)
          executable_action.update_state_change_status(@task.model_handle,:completed)  #this send pending changes' states
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
        @task.subtasks.each do |subtask|
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
        threads = @task.subtasks.map do |subtask|
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

      def debug_pp(x)
        @@debug_lock.synchronize{pp x}
      end
      @@debug_lock = Mutex.new
    end
  end
end
