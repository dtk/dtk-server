# RICH-WF: right now mimicking ruote where have seperate workflow that mirrors task structure and pointer back to task 
module DTK 
  module WorkflowAdapter
    class Simple < Workflow
      def initialize(top_task,task=nil)
        super(top_task)
        @task = task||top_task
      end

      def execute(top_task_id)
        workflow = self.class.generate_workflow(@top_task,@task)
        # RICH-WF: needs to be written by having each child class put in logic
        workflow.follow_workflow()
      end

     private
      attr_reader :task
      # RICH-WF: this function can do the decomposition where there may be a base task that decomposes into multiple ones
      def self.generate_workflow(top_task,task)
        if task[:executable_action]
          ExecutableAction.new(top_task,task)
        elsif task[:temporal_order] == "sequential"
          Sequential.new(top_task,task)
        elsif task[:temporal_order] == "concurrent"
          Concurrent.new(top_task,task)
        else
          Log.error("do not have rules to process task")
        end
      end

      class ExecutableAction < self
        def follow_workflow()
          #TODO: needs to call workflow#process_executable_action
          process_executable_action(task,top_task_idh)
        end

        def debug_summary()
          node = task[:executable_action][:node]||{}
          summary = {
            :action_type => task[:executable_action_type],
            :node => {:id => node[:id],:name => node[:display_name]}
          }
          [self.class,summary]
        end
      end

      module NestedWFMixin
        def initialize(top_task,task)
          super
          @children = task.subtasks.map{|sub_task|self.class.generate_workflow(@top_task,sub_task)}
        end 
        attr_reader :children

        def debug_summary()
          [self.class,@children.map{|wf|wf.debug_summary()}]
        end
      end
      class Sequential < self
        include NestedWFMixin
        def follow_workflow()
          pp [:debug_print,debug_summary()]
          raise Error.new("fn must be written")
        end
      end

      class Concurrent < self
        include NestedWFMixin
        def follow_workflow()
          pp [:debug_print,debug_summary()]
          raise Error.new("fn must be written")
        end
      end
    end
  end
end
=begin
# RICH-WF: below where old methods that intermixed created workflow and execvuting on them; now we need to write
follow_workflow for both classes; teh follow workflow for the concurrent one shoudl leevrage the pattern used in spawningthreads to do scp/ssh, but more general to execute any executable action

      def process_sequential(task)
        status = :succeeded
        mark_as_not_reached = false
        task.subtasks.each do |subtask|
          subtask_wf = Simple.new(subtask)
          if mark_as_not_reached
            # TODO: Workflow#update_task has been removed
            subtask_wf.update_task(:status => "not_reached")
          else
            subtask_status = subtask_wf.execute(top_task_idh) 
            # TODO: what to sent whole task status when failue but not task[:action_on_failure] == "abort"
            if subtask_status == :failed 
              status = :failed
              mark_as_not_reached = true if  task[:action_on_failure] == "abort"
            end
          end
        end
        task.update(:status => status.to_s)
        status
      end

      def process_concurrent(task)
        status = :succeeded
        lock = Mutex.new
        # TODO: not killing concurrent subtasks if one failes
        user_object  = ::DTK::CurrentSession.new.user_object()
        threads = task.subtasks.map do |subtask|
          CreateThread.defer_with_session(user_object) do 
            subtask_status = Simple.new(subtask).execute(top_task_idh)
            lock.synchronize do
              status = :failed if subtask_status == :failed 
            end
          end
        end
pp [:threads, threads]
        threads.each{|t| t.join}
        task.update(:status => status.to_s)
        status
      end
    end
  end
end
=end
