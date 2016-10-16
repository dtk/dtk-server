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
    class Cleanup < self
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

      def execute_cleanup_action(top_task_idh)
        top_task = top_task_idh.create_object()

        assembly =
          if subtask_assembly = self[:assembly]
            top_task.id_handle.createIDH(id: subtask_assembly[:id], model_name: :assembly).create_object
          else
            top_task.assembly
          end

        if assembly
          assembly_instance = assembly.copy_as_assembly_instance

          if self[:node] || self[:component]
            assembly_instance.send(self[:delete_action], *self[:delete_params])
            module_branch = AssemblyModule::Service.get_service_instance_branch(assembly_instance)
            CommonDSL::Generate::ServiceInstance.generate_dsl(assembly_instance, module_branch)
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

      def set_inter_node_stage!(internode_stage_index)
        self[:inter_node_stage] = internode_stage_index && internode_stage_index.to_s
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
        ConfigAgent::Type::Symbol.cleanup
      end

      def update_state_change_status(task_mh, status)
        # no op if no associated state change
        if self[:state_change_id]
          update_state_change_status_aux(task_mh, status, [self[:state_change_id]])
        end
      end

      def nodes(opts = {})
        node_or_ng = self[:node]
        nodes =
          if node_or_ng.is_node_group?()
            node_or_ng.get_node_group_members()
          else
            [node_or_ng]
          end
        if cols = opts[:cols]
          nodes.each { |node| node.update_object!(*cols) }
        end
        nodes
      end

      def node_id
        self[:node][:id]
      end

      def create_node_group_member(node)
        self.class.new(:hash, node: node, node_group_member: true)
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
    end
  end
end; end