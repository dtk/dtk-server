module DTK
  class Workflow
    r8_nested_require('workflow','guard')

    #Rich: moved thess to be in config file so each developer can test different configs
    # Configuration for 'inter_node_temporal_coordination_mode'; Values: 'STAGES' 'GUARDS'
    # @@inter_node_temporal_coordination_mode = "STAGES"
    # Configuration for 'intra_node_temporal_coordination_mode'; Values: 'STAGES' 'TOTAL_ORDER'
    # @@intra_node_temporal_coordination_mode = "STAGES"
    class << self
      def guards_mode?
        inter_node_temporal_coordination_mode() == "GUARDS"
      end
      def stages_mode?
        inter_node_temporal_coordination_mode() == "STAGES"
      end
      def intra_node_total_order?
        intra_node_temporal_coordination_mode() == "TOTAL_ORDER"
      end
      def intra_node_stages?
        intra_node_temporal_coordination_mode() == "STAGES"
      end

     private
      def inter_node_temporal_coordination_mode()
        @inter_node_temporal_coordination_mode ||= R8::Config[:workflow][:temporal_coordination][:inter_node]
      end
      def intra_node_temporal_coordination_mode()
        @intra_node_temporal_coordination_mode ||= R8::Config[:workflow][:temporal_coordination][:intra_node]
      end
    end

    # Variables to enable cancelation of tasks. 
    # 'active_workflows' holds current active tasks executing on Ruote engine
    # Lock is needed in case of concurrent execution
    @@active_workflows = Hash.new
    @@Lock = Mutex.new
 
    def defer_execution()
      user_object  = ::DTK::CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object) do
      #  pp [:new_thread_from_defer, Thread.current, Thread.list]
        raise Error.new("not implemented: putting block in reactor loop when not using eventmachine web server") unless R8EM.reactor_running?
        begin
          pp "starting top_task_id = #{@top_task.id.to_s}"          
          #RICH-WF: for both Ruote and Simple think we dont need to pass in @top_task.id.to_s
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

    def self.cancel(task_id, task)
      @@Lock.synchronize do
        # Amar: If task is present in '@@active_workflows' ruote process will be cancelled, 
        #       task status updated and resources cleaned up
        #       If task loaded from DB has status executing, but not present in '@@active_workflows'
        #       it means, unexpected server behavior (i.e. server restarted during converge), 
        #       and only task status will get updated.
        #       Otherwise, raise error task not running.
        if @@active_workflows[task_id]
          @@active_workflows[task_id].cancel()
          @@active_workflows.delete(task_id)
        elsif task && task.is_status?("executing")
          task.update_task_subtask_status("cancelled",Task::Action::Result::Cancelled.new())
        else
          raise ErrorUsage, "No task running with TASK_ID: #{task_id}"
        end
      end
    end

    def self.kill(task_id)
      @@Lock.synchronize do 
        raise Error.new("There are no tasks running with TASK_ID: #{task_id}") unless @@active_workflows[task_id]
        @@active_workflows[task_id].kill()
        @@active_workflows.delete(task_id)
      end
    end

    def self.create(top_task)
      ret = Adapter.klass(top_task).new(top_task)
      @@Lock.synchronize{ @@active_workflows[top_task[:id].to_s] = ret }
      ret
    end

    def process_executable_action(task)
      self.class.process_executable_action(task,top_task_idh)
    end

    attr_reader :top_task, :guards

   private
    def self.process_executable_action(task,top_task_idh)
      CommandAndControl.execute_task_action(task,top_task_idh)
    end

    class Adapter
      def self.klass(top_task=nil)
        #RICH-WF: not necssary to cache (ie., use @klass)
        #return @klass if  @klass
        begin
          type = type(top_task)
          r8_nested_require("workflow","adapters/#{type}")
          # @klass = ::XYZ::WorkflowAdapter.const_get type.to_s.capitalize
          WorkflowAdapter.const_get type.to_s.capitalize
        rescue LoadError => e
          pp [e,e.backtrace[0..5]]
          raise.Error.new("cannot find workflow adapter")
        end
      end
      private
      #RICH-WF: stub function to call Simple when top_task is install_agents
      def self.type(top_task=nil)
        if (top_task||{})[:display_name] == "install_agents"
        #  :simple
          :ruote
        else
          R8::Config[:workflow][:type].to_sym
        end
      end
    end

    def initialize(top_task)
      @top_task = top_task
      @guards = {:internal => Array.new, :external => Array.new}
      if Workflow.guards_mode?
        Guard.ret_guards(top_task).each do |guard|
          @guards[guard.internal_or_external()] << guard
        end
      end
    end

    def top_task_idh()
      @top_task.id_handle()
    end

  end
end

