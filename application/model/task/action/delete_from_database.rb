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
module DTK; class Task
  class Action
    class DeleteFromDatabase < self
      def initialize(_type, hash, task_idh = nil)
        super(hash)
      end

      def self.create_hash(assembly, component, node, opts = {})
        hash = {
          assembly_idh: assembly.id_handle(),
          component: component,
          node: node,
          assembly: assembly,
          delete_action: opts[:delete_action],
          delete_params: opts[:delete_params]
        }
        new(:hash, hash)
      end

      def execute_delete_action(top_task_idh)
        case self[:delete_action]
         when 'delete_component'
          execute_delete_component(top_task_idh)
         else
          fail Error.new("Unsupported action type '#{self[:delete_action]}'!")
         end
      end

      def node_is_node_group?
        self[:node].is_node_group?()
      end

      def ret_command_and_control_adapter_info
        [:node_config, :server]
      end

      # virtual gets overwritten
      # updates object and the tasks in the model
      def get_and_update_attributes!(_task)
        # raise "You need to implement 'get_and_update_attributes!' method for class #{self.class}"
      end

      # virtual gets overwritten
      def add_internal_guards!(_guards)
        # raise "You need to implement 'add_internal_guards!' method for class #{self.class}"
      end

      def config_agent_type
        ConfigAgent::Type::Symbol.delete_from_database
      end

      def update_state_change_status(task_mh, status)
        # no op if no associated state change
        if self[:state_change_id]
          update_state_change_status_aux(task_mh, status, [self[:state_change_id]])
        end
      end

      private

      def execute_delete_component(top_task_idh)
        top_task = top_task_idh.create_object()
        if assembly = top_task.assembly
          assembly_instance = assembly.copy_as_assembly_instance
          delete_params = self[:delete_params]
          cmp_id = delete_params[:cmp_idh][:guid]
          cmp_idh = top_task.id_handle(model_name: :component, id: cmp_id)
          node_id = delete_params[:node_id]
          assembly_instance.delete_component(cmp_idh, node_id)
        else
          fail Error.new("Unexpected that top task does not have assembly!")
        end
      end
    end
  end
end; end