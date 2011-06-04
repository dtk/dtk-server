module XYZ
  class Workflow
    def defer_execution(top_level_task)
      CreateThread.defer do
      #  pp [:new_thread_from_defer, Thread.current, Thread.list]
        raise Error.new("not implemented: putting block in reactor loop when not using eventmachine web server") unless R8EM.reactor_running?
        begin
          top_task_id = top_level_task.id_handle.get_id()
          pp "starting top_task_id = #{top_task_id.to_s}"
          execute()
         rescue Exception => e
          Log.error("error in commit background job: #{e.inspect}")
          pp e.backtrace[0..10]
        end
        pp "end of commit_changes defer"
        pp "----------------"
      end
    end

    #virtual fns that get ovewritten
    def execute(top_task_idh=nil)
    end
    ######

    def self.create(task)
      Adapter.new(task)
    end

    def update_task(hash)
      @task.update(hash)
    end

    attr_reader :task

    def process_executable_action(executable_action,top_task_idh)
      self.class.process_executable_action(@task,executable_action,top_task_idh)
    end

   private

    def self.process_executable_action(task,executable_action,top_task_idh)
      CommandAndControl.execute_task_action(executable_action,task,top_task_idh)
    end

    klass = self
    begin
      type = R8::Config[:workflow][:type]
      require File.expand_path("#{UTILS_DIR}/internal/workflow/adapters/#{type}", File.dirname(__FILE__))
      klass = XYZ::WorkflowAdapter.const_get type.capitalize
     rescue LoadError => e
      pp [e,e.backtrace[0..5]]
      raise.Error.new("cannot find workflow adapter")
    end
    Adapter = klass

    def initialize(task)
      @task = task
    end
  end
end

