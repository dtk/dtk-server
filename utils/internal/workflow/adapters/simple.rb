#TODO: if we use this; it wil be needed to be updated
module XYZ 
  module WorkflowAdapter
    class Simple < XYZ::Workflow
      def execute()
        top_task_idh = @ttop_ask.id_handle()
        executable_action = @task[:executable_action]
        if executable_action
          process_executable_action(@task,top_task_idh)
        elsif @task[:temporal_order] == "sequential"
          process_sequential(top_task_idh)
        elsif @task[:temporal_order] == "concurrent"
          process_concurrent(top_task_idh)
        else
          Log.error("do not have rules to process task")
        end
      end

     private
      def process_sequential(top_task_idh)
        status = :succeeded
        mark_as_not_reached = false
        @task.subtasks.each do |subtask|
          subtask_wf = Simple.new(subtask)
          if mark_as_not_reached
            #TODO: Workflow#update_task has been removed
            subtask_wf.update_task(:status => "not_reached")
          else
            subtask_status = subtask_wf.execute(top_task_idh) 
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

      def process_concurrent(top_task_idh)
        status = :succeeded
        lock = Mutex.new
        #TODO: not killing concurrent subtasks if one failes
        user_object  = ::DTK::CurrentSession.new.user_object()
        threads = @task.subtasks.map do |subtask|
          CreateThread.defer_with_session(user_object) do 
            subtask_status = Simple.new(subtask).execute(top_task_idh)
            lock.synchronize do
              status = :failed if subtask_status == :failed 
            end
          end
        end
pp [:threads, threads]
        threads.each{|t| t.join}
        @task.update(:status => status.to_s)
        status
      end
    end
  end
end
