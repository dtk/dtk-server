module DTK
  class Workflow
    r8_nested_require('workflow', 'guard')
    r8_nested_require('workflow', 'call_commands')
    include CallCommandsMixin

    class << self
      def guards_mode?
        inter_node_temporal_coordination_mode() == 'GUARDS'
      end

      def stages_mode?
        inter_node_temporal_coordination_mode() == 'STAGES'
      end

      def intra_node_total_order?
        intra_node_temporal_coordination_mode() == 'TOTAL_ORDER'
      end

      def intra_node_stages?
        intra_node_temporal_coordination_mode() == 'STAGES'
      end

      private

      def inter_node_temporal_coordination_mode
        @inter_node_temporal_coordination_mode ||= R8::Config[:workflow][:temporal_coordination][:inter_node]
      end

      def intra_node_temporal_coordination_mode
        @intra_node_temporal_coordination_mode ||= R8::Config[:workflow][:temporal_coordination][:intra_node]
      end
    end

    # Making ActiveWorkflow a class to facilitate debuging
    class ActiveWorkflow < Hash
      def delete(task_id)
        super(task_id.to_i)
      end

      def [](task_id)
        super(task_id.to_i)
      end

      def []=(task_id, wf)
        super(task_id.to_i, wf)
      end
    end

    # Variables to enable cancelation of tasks.
    # 'active_workflows' holds current active tasks executing on Ruote engine
    # Lock is needed in case of concurrent execution
    @@active_workflows = ActiveWorkflow.new
    @@Lock = Mutex.new

    def defer_execution
      # start EM for passanger
      R8EM.start_em_for_passenger?()

      user_object  = CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object, Ramaze::Current.session) do
        #  pp [:new_thread_from_defer, Thread.current, Thread.list]
        fail Error.new('not implemented: putting block in reactor loop when not using eventmachine web server') unless R8EM.reactor_running?
        begin
          pp "starting top_task_id = #{@top_task.id}"
          # RICH-WF: for both Ruote and Simple think we dont need to pass in @top_task.id.to_s
          execute(@top_task.id.to_s)
         rescue Exception => e
          Log.error("error in commit background job: #{e.inspect}")
          pp e.backtrace[0..10]
        end
        pp 'end of commit_changes defer'
        pp '----------------'
        @@Lock.synchronize { @@active_workflows.delete(@top_task.id) }
      end
    end

    # virtual fns that get ovewritten
    def execute
    end
    ######

    def self.cancel(task)
      task_id = task.id()
      unless task.is_status?('executing')
        fail ErrorUsage, "Task with id '#{task_id} is not executing"
      end

      # This shuts down workflow from advancing; however there can be stragler callbascks coming in
      @@Lock.synchronize do
        if @@active_workflows[task_id]
          @@active_workflows[task_id].cancel()
          @@active_workflows.delete(task_id)
        end
      end

      # update task status
      task.update_at_task_cancelled(Task::Action::Result::Cancelled.new())

    end

    def self.task_is_active?(task_id)
      !!@@active_workflows[task_id]
    end
    def self.kill(task_id)
      @@Lock.synchronize do
        if task_is_active?(task_id)
          @@active_workflows[task_id].kill()
          @@active_workflows.delete(task_id)
        else
          Log.info("There are no tasks running with TASK_ID: #{task_id}")
        end
      end
    end

    def self.create(top_task)
      ret = Adapter.klass(top_task).new(top_task)
      @@Lock.synchronize { @@active_workflows[top_task[:id]] = ret }
      ret
    end

    attr_reader :top_task, :guards

    private

    class Adapter
      def self.klass(top_task = nil)
        # RICH-WF: not necssary to cache (ie., use @klass)
        # return @klass if  @klass
        type = type(top_task)
        r8_nested_require('workflow', "adapters/#{type}")
        # @klass = ::XYZ::WorkflowAdapter.const_get type.to_s.capitalize
        WorkflowAdapter.const_get type.to_s.capitalize
      rescue LoadError => e
        pp [e, e.backtrace[0..5]]
        raise.Error.new('cannot find workflow adapter')
      end

      private

      # RICH-WF: stub function to call Simple when top_task is install_agents
      def self.type(top_task = nil)
        if (top_task || {})[:display_name] == 'install_agents'
          :ruote
        else
          R8::Config[:workflow][:type].to_sym
        end
      end
    end

    def initialize(top_task)
      @top_task = top_task
      @guards = { internal: [], external: [] }
      if Workflow.guards_mode?
        Guard.ret_guards(top_task).each do |guard|
          @guards[guard.internal_or_external()] << guard
        end
      end
    end

    def top_task_idh
      @top_task.id_handle()
    end
  end
end
