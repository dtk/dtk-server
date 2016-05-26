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
    class CommandAndControlAction < self
      REPEAT_COUNT = 60

      def initialize(_type, hash, task_idh = nil)
        super(hash)
      end

      def self.create_hash(assembly, action, params, node, opts = {})
        hash = {
          assembly_idh: assembly.id_handle(),
          assembly: assembly,
          cc_action: action,
          cc_params: params,
          node: node
        }
        new(:hash, hash)
      end

      def execute_command_and_control_action(top_task_idh, task_idh)
        if assembly = top_task_idh.create_object().assembly
          assembly_instance = assembly.copy_as_assembly_instance

          leaf_nodes = assembly_instance.get_leaf_nodes()
          node = leaf_nodes.find{|n| n[:id] == self[:node][:id]}

          CommandAndControl.send(self[:cc_action], node)
          status = nil

          REPEAT_COUNT.times do
            status = CommandAndControl.get_node_operational_status(node)
            break if status.nil? || status.to_sym == :terminated
            sleep(1)
          end

          fail Error.new("Timeout reached! Node is not stopped properly!") if status && status.to_sym != :terminated
        else
          fail Error.new("Unexpected that top task does not have assembly!")
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
        ConfigAgent::Type::Symbol.command_and_control_action
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