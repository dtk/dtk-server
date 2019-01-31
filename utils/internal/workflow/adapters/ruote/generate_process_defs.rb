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
  module WorkflowAdapter
    module RuoteGenerateProcessDefs
      require_relative('generate_process_defs/context')
      require_relative('generate_process_defs/bulk_create')

      @@count = 0
      def compute_process_def(task)
        count = @@count += 1 #TODO: see if we need to keep generating new ones or whether we can (delete) and reuse
        top_task_idh = task.id_handle
        name = "process-#{count}"
        context = Context::NoGuards.new(top_task_idh)
        ['define', { 'name' => name }, [compute_process_body(task, context)]]
      end

      private

      ####semantic processing
      def decomposition(task, context)
        action      = task[:executable_action]
        action_type = action.type_for_workflow

        case action_type
        when :create_node
          participant_executable_action(:execute_on_node, task, context, task_start: true, task_end: true)
        when :config
          if action.execute_on_server?
            main = participant_executable_action(:execute_on_node, task, context, task_type: 'config_node', task_end: true, task_start: true)
            sequence([main])
          else
            node_is_ready = participant_executable_action(:detect_created_node_is_ready, task, context, task_type: 'detect_created_node_is_ready', task_start: true)

            authorize_action = participant_executable_action(:authorize_node, task, context, task_type: 'authorize_node')
            sync_agent_code =
              if R8::Config[:node_agent_git_clone][:mode] != 'off'
                participant_executable_action(:sync_agent_code, task, context, task_type: 'sync_agent_code')
              end
                main = participant_executable_action(:execute_on_node, task, context, task_type: 'config_node', task_end: true)
            sequence_tasks = [node_is_ready, sync_agent_code, authorize_action, main].compact
            sequence(*sequence_tasks)
          end
        when :delete_from_database
          main = participant_executable_action(:delete_from_database, task, context, task_type: 'delete_from_database', task_start: true, task_end: true)
          sequence([main])
        when :command_and_control_action
          main = participant_executable_action(:command_and_control_action, task, context, task_type: 'delete_node', task_start: true, task_end: true)
          sequence([main])
        when :cleanup
          main = participant_executable_action(:cleanup, task, context, task_type: 'cleanup', task_start: true, task_end: true)
          sequence([main])
        else
          fail Error, "Unexpected action type for workflow '#{action_type}'"
        end
      end

      #### synactic processing
      def compute_process_body(task, context)
        # TODO: below put in hack for DTK-2471 that needs to be cleaned up
        # Does not allow mixed bosh and non bosh
        # This intercepts a create node stages subtask and bulks it up so taht it is a set of queue node tasks with last being dispatch
        case task.temporal_type
          when :leaf
            BulkCreate.create_node?(task, context, self) || compute_process_executable_action(task, context)
          # For sequentail and concurrent subatsks want to pass in a breakpooint if its parent has it            
          when :sequential
            pass_in_breakpoint!(:sequential, task)
            compute_process_body_sequential(task.subtasks, context)
          when :concurrent
            pass_in_breakpoint!(:concurrent, task)
            BulkCreate.create_nodes?(task.subtasks, context, self) || compute_process_body_concurrent(task.subtasks, context)
          else
            fail Error, "Unexpected temporal type '#{task.temporal_type}'"
        end
      end

      # Logic being used to pass in breakpoint is to set it on first for sequential and all for concurrent 
      def pass_in_breakpoint!(temporal_type, task)
        if task[:breakpoint]
          case task.temporal_type
          when :sequential
            if subtask = task.subtasks.first
              subtask[:breakpoint] = true
            end
          when :concurrent
            task.subtasks.map { |subtask| subtask[:breakpoint] = true }
          end
        end
      end

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

        task_id = task.id
        Ruote::TaskInfo.set(task_id, context.top_task_idh.get_id, task_info, task_type: opts[:task_type])
        participant_params = opts.merge(
          task_id: task_id,
          top_task_id: context.top_task_idh.get_id
        )
        participant(name, participant_params)
      end
      public :participant_executable_action

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
      public :sequence

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
