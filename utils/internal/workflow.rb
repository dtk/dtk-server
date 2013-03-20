module XYZ
  class Workflow

    # Variables to enable cancelation of tasks. 
    # 'active_workflows' holds current active tasks executing on Ruote engine
    # Lock is needed in case of concurrent execution
    @@active_workflows = Hash.new
    @@Lock = Mutex.new

    def defer_execution()
      CreateThread.defer do
      #  pp [:new_thread_from_defer, Thread.current, Thread.list]
        raise Error.new("not implemented: putting block in reactor loop when not using eventmachine web server") unless R8EM.reactor_running?
        begin
          pp "starting top_task_id = #{@top_task.id.to_s}"
          execute(@top_task.id.to_s)
         rescue Exception => e
          Log.error("error in commit background job: #{e.inspect}")
          pp e.backtrace[0..10]
        end
        pp "end of commit_changes defer"
        pp "----------------"
        @@Lock.synchronize{ @@active_workflows.delete(@top_task.id.to_s) }
      end
    end

    #virtual fns that get ovewritten
    def execute()
    end
    ######

    def self.cancel(task_id)
      @@Lock.synchronize do 
        raise Error.new("There are no tasks running with TASK_ID: #{task_id}") unless @@active_workflows[task_id]
        @@active_workflows[task_id].cancel()
        @@active_workflows.delete(task_id)
      end
    end

    def self.kill(task_id)
      @@Lock.synchronize do 
        raise Error.new("There are no tasks running with TASK_ID: #{task_id}") unless @@active_workflows[task_id]
        @@active_workflows[task_id].kill()
        @@active_workflows.delete(task_id)
      end
    end

    def self.create(top_task,guards=nil)
      adapter = Adapter.new(top_task,guards)
      @@Lock.synchronize{ @@active_workflows[top_task[:id].to_s] = adapter }
      return adapter
    end

    def process_executable_action(task)
      self.class.process_executable_action(task,top_task_idh)
    end

    attr_reader :top_task, :guards

   private
    def self.process_executable_action(task,top_task_idh)
      CommandAndControl.execute_task_action(task,top_task_idh)
    end

    klass = self
    begin
      type = R8::Config[:workflow][:type]
      r8_nested_require("workflow","adapters/#{type}")
      klass = XYZ::WorkflowAdapter.const_get type.capitalize
     rescue LoadError => e
      pp [e,e.backtrace[0..5]]
      raise.Error.new("cannot find workflow adapter")
    end
    Adapter = klass

    def initialize(top_task,guards)
      @top_task = top_task
      @guards = {:internal => Array.new, :external => Array.new}
      (guards||[]).each do |guard|
        type = guard[:guarded][:node][:id] ==  guard[:guard][:node][:id] ? :internal : :external
        @guards[type] << guard
      end
    end

    def top_task_idh()
      @top_task.id_handle()
    end

  end
end

