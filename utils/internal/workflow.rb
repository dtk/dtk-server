module XYZ
  class Workflow
    def defer_execution()
      CreateThread.defer do
      #  pp [:new_thread_from_defer, Thread.current, Thread.list]
        raise Error.new("not implemented: putting block in reactor loop when not using eventmachine web server") unless R8EM.reactor_running?
        begin
          pp "starting top_task_id = #{@top_task.id.to_s}"
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
    def execute()
    end
    ######

    def self.create(top_task,guards=nil)
      Adapter.new(top_task,guards)
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

