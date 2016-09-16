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
        assembly = nil

        if assembly_in_task_action = self[:assembly]
          action_assembly_idh = top_task_idh.createIDH(id: assembly_in_task_action[:id], model_name: :assembly)
          assembly = action_assembly_idh.create_object if action_assembly_idh
        end

        if assembly ||= top_task_idh.create_object().assembly
          assembly_instance = assembly.copy_as_assembly_instance

          leaf_nodes = assembly_instance.get_leaf_nodes()
          node = leaf_nodes.find{|n| n[:id] == self[:node][:id]}
          expected_status = :terminated

          if self[:cc_action].eql?('stop_instances')
            expected_status = :stopped
            CommandAndControl.send(self[:cc_action], [node])
            node.attribute.clear_host_addresses()
          else
            CommandAndControl.send(self[:cc_action], node)
          end
          status = nil

          REPEAT_COUNT.times do
            status = CommandAndControl.get_node_operational_status(node)
            break if status.nil? || status.to_sym == expected_status
            sleep(1)
          end

          fail Error.new("Timeout reached! Node is not stopped properly!") if status && status.to_sym != expected_status
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

      def self.node_status(object, _opts)
        node = object[:node] || {}
        ext_ref = node[:external_ref] || {}
        kv_array =
          [{ name: node[:display_name] },
           { id: node[:id] },
           { type: ext_ref[:type] },
           { image_id: ext_ref[:image_id] },
           { size: ext_ref[:size] }
          ]
        PrettyPrintHash.new.set?(*kv_array)
      end

      def self.status(object, opts)
        ret = PrettyPrintHash.new
        ret[:node] = node_status(object, opts)
        ret
      end

      # for debugging
      def self.pretty_print_hash(object)
        ret = PrettyPrintHash.new
        ret[:node] = (object[:node] || {})[:display_name]
        ret
      end
    end
  end
end; end