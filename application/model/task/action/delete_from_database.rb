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
          delete_params: opts[:delete_params],
          opts: opts
        }
        new(:hash, hash)
      end

      def execute_delete_action(top_task_idh)
        top_task = top_task_idh.create_object()
        assembly = top_task.assembly

        if assembly
          assembly_instance = assembly.copy_as_assembly_instance

          if self[:node] || self[:component]
            assembly_instance.send(self[:delete_action], *self[:delete_params])
          else
            component_idh = assembly.id_handle.createIDH(id: assembly.id(), model_name: :component)
            assembly_instance.class.send(self[:delete_action], component_idh, self[:opts])
          end
        else
          fail Error.new("Unexpected that top task does not have assembly!")
        end
      end

      def node_is_node_group?
        return false unless self[:node]
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
    end
  end
end; end