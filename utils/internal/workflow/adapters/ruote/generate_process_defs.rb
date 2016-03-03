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
require 'json'
module DTK
  module WorkflowAdapter
    module RuoteGenerateProcessDefs
      r8_nested_require('generate_process_defs', 'context')
      include ContextMixin

      @@count = 0
      def compute_process_def(task, guards)
        count = @@count += 1 #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        top_task_idh = task.id_handle()
        name = "process-#{count}"
        #TODO: this needs to be changed if we use guards again in the temporal ordering
        context = Context.create(guards, top_task_idh)
        ['define', { 'name' => name }, [compute_process_body(task, context)]]
      end

      private

      ####semantic processing
      def decomposition(task, context)
        action = task[:executable_action]
        if action.is_a?(Task::Action::PowerOnNode)
          detect_when_ready = participant_executable_action(:power_on_node, task, context, task_type: 'power_on_node', task_end: true, task_start: true)
          sequence([detect_when_ready])
        elsif action.is_a?(Task::Action::InstallAgent)
          main = participant_executable_action(:install_agent, task, context, task_type: 'install_agent', task_start: true, task_end: true)
          sequence([main])
        elsif action.is_a?(Task::Action::ExecuteSmoketest)
          main = participant_executable_action(:execute_smoketest, task, context, task_type: 'execute_smoketest', task_start: true, task_end: true)
          sequence([main])
        elsif action.is_a?(Task::Action::CreateNode)
          main = participant_executable_action(:create_node, task, context, task_start: true)
          post_part = participant_executable_action(:detect_created_node_is_ready, task, context, task_type: 'post', task_end: true)
          sequence(main, post_part)
        elsif action.is_a?(Task::Action::ConfigNode)
          guards = nil
          if guard_tasks = context.get_guard_tasks(action)
            guards = ret_guards(guard_tasks)
          end

          if action.execute_on_server?
            main = participant_executable_action(:execute_on_node, task, context, task_type: 'config_node', task_end: true, task_start: true)
            sequence([main])
          else
            authorize_action = participant_executable_action(:authorize_node, task, context, task_type: 'authorize_node', task_start: true)
            sync_agent_code =
              if R8::Config[:node_agent_git_clone][:mode] != 'off'
                participant_executable_action(:sync_agent_code, task, context, task_type: 'sync_agent_code')
              end
                main = participant_executable_action(:execute_on_node, task, context, task_type: 'config_node', task_end: true)
            sequence_tasks = [guards, sync_agent_code, authorize_action, main].compact
            sequence(*sequence_tasks)
          end
        end
      end

      ####synactic processing
      def compute_process_body(task, context)
        case task.temporal_type()
          when :leaf
            compute_process_executable_action(task, context)
          when :sequential
            compute_process_body_sequential(task.subtasks, context)
          when :concurrent
            # TODO: hack for DTK-2471 that needs to be cleaned up
            # Does not allow mxied bosh and non bosh
            # This intercepts a create node stages subtask and makes into one queue tasks
            bulked_up_create_nodes?(task.subtasks, context) || compute_process_body_concurrent(task.subtasks, context)
          else
            Log.error('do not have rules to process task')
        end
      end

      # TODO: DTK-2471: begin: ============================================
      def bulked_up_create_nodes?(subtasks, context)
        unless subtasks.empty?
          if subtasks.find { |subtask| bosh_create_node?(subtask) }
            if subtasks.find { |subtask| ! bosh_create_node?(subtask) }
              fail ErrorUsage.new("Not Handling create nodes with mixed BOSH and non-BOSH nodes")
            end
            compute_process_body_reformatted_bulked_up_create_nodes(subtasks, context)
          end
        end
      end

      def bosh_create_node?(subtask)
        if executable_action = subtask[:executable_action]
          if executable_action.kind_of?(Task::Action::CreateNode)
            if external_ref = (executable_action[:node] || {})[:external_ref]
              external_ref[:type] == 'bosh_instance'
            end
          end
        end
      end
      
      def compute_process_body_reformatted_bulked_up_create_nodes(subtasks, context)
        # mark last subtask to initiate create nodes
        mark_initiate_create_nodes!(subtasks)
        queue_tasks = subtasks.map do |task|
          participant_executable_action(:create_node, task, context, task_start: true)
        end
        detect_created_tasks = subtasks.map do |task|
          participant_executable_action(:detect_created_node_is_ready, task, context, task_type: 'post', task_end: true)
        end
        # TODO: double check this logic; but since the detect_created_tasks doing same thing; we can make them sequential and then
        # have first one cache results for rest
        sequence(queue_tasks + detect_created_tasks)
      end

      def mark_initiate_create_nodes!(subtasks)
        last_task = subtasks.last
        last_task[:executable_action].merge!(initiate_create_nodes: true)
      end

      # TODO: DTK-2471: end: ============================================

      def compute_process_body_sequential(subtasks, context)
        sts = subtasks.map do |t|
          new_context = context.new_sequential_context(t)
          compute_process_body(t, new_context)
        end
        sequence(sts)
      end

      def compute_process_body_concurrent(subtasks, context)
        new_context = context.new_concurrent_context(subtasks)
        concurrence(subtasks.map { |t| compute_process_body(t, new_context) })
      end

      def compute_process_executable_action(task, context)
        decomposition(task, context) || participant_executable_action(:execute_on_node, task, context, task_start: true, task_end: true)
      end

      def participant_executable_action(name, task, context, opts = {})
        executable_action = task[:executable_action]
        task_info = {
          'action' => executable_action,
          'workflow' => self,
          'task' => task,
          'top_task_idh' => context.top_task_idh
        }

        task_id = task.id()
        Ruote::TaskInfo.set(task_id, context.top_task_idh.get_id(), task_info, task_type: opts[:task_type])
        participant_params = opts.merge(
          task_id: task_id,
          top_task_id: context.top_task_idh.get_id()
        )
        participant(name, participant_params)
      end

      # formatting fns
      def participant(name, opts = {})
        # we set user and session information so that we can reflect that information on newly created threads via Ruote
        opts.merge!(user_info: { user: CurrentSession.new.get_user_object.to_json_hash })

        ['participant', to_str_form({ 'ref' => name }.merge(opts)), []]
      end

      def participants_for_tasks
        @participants_for_tasks ||= {
          # TODO: need condition that signifies detect_created_node_is_ready succeeded
          Task::Action::CreateNode => :detect_created_node_is_ready,
          Task::Action::ConfigNode => :execute_on_node
        }
      end

      def sequence(*subtask_array_x)
        subtask_array = subtask_array_x.size == 1 ? subtask_array_x.first : subtask_array_x
        ['sequence', {}, subtask_array]
      end

      def concurrence(*subtask_array_x)
        subtask_array = subtask_array_x.size == 1 ? subtask_array_x.first : subtask_array_x
        ['concurrence', { 'merge_type' => ConcurrenceMergeType }, subtask_array]
      end
      ConcurrenceMergeType = 'ignore' # "stack" || "union" || "isolate" || "stack"

      def to_str_form(hash)
        hash.inject({}) do |h, (k, v)|
          h.merge((k.is_a?(Symbol) ? k.to_s : k) => (v.is_a?(Symbol) ? v.to_s : v))
        end
      end
    end
  end
end
