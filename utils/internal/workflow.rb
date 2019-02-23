#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
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

    def execute_in_current_thread
      # save top task data for use in cancellation
      # TODO: DTK-3686; comment1; the following will not work if there are two simulatneous instances of this class (@@workflow_agent_cache) @@workflow_agent_cache is just one value at teh class level
      # instead; instaed consider declaring outside of function @@workflow_agent_cache = {} and below
      # @@workflow_agent_cache[@top_task.id] = @top_task
      @@workflow_agent_cache = @top_task
      execute(@top_task.id.to_s)
    end

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

      # if cancelling inner workflow: `task` has config agent type `workflow`
      # if cancelling top task: `task` is XYZ::Task
      if is_inner_workflow? task
      # TODO: DTK-3686; see comment1 above; there I proposed @@workflow_agent_cache[@top_task.id] = @top_task, 
      # but see here that the only index you have comes from task. So you might in execute_in_current_thread have more general form
      # @@workflow_agent_cache[agent_cache_index] = @top_task 
      # where execute_in_current_thread needs to compute some agent_cache_index that then can be ascertained here from task
        task = @@workflow_agent_cache
        reset_workflow_agent_cache
      end

      task_id = task.id
      unless task.has_status?(:executing) || task.has_status?(:debugging)
        fail ErrorUsage, "Task with id '#{task_id}' is not executing"
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

    def self.is_inner_workflow?(task)
      task.respond_to?(:config_agent_type) && task.config_agent_type == 'workflow'
    end

    # TODO: DTK-3686; see comment1 above; this needs to be modified in accordnace to other changes you put in
    def self.reset_workflow_agent_cache
      @@workflow_agent_cache = nil
    end

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
