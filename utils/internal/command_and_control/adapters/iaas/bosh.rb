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
  class CommandAndControl::IAAS
    class Bosh < self
      r8_nested_require('bosh', 'client')
      r8_nested_require('bosh', 'create_nodes')
      r8_nested_require('bosh', 'instance_id')

      def execute(_task_idh, top_task_idh, task_action)
        top_task = top_task_idh.create_object()
        # Assumption is that all all task_action's actions associated with same top_task_id have same target
        target = task_action.target()
        create_nodes = CreateNodes.get_or_create(top_task, target)
        create_nodes.queue(task_action)
        if task_action[:trigger_create_nodes]
        create_nodes.execute_if_last_bosh_create_subtask?(task_action)
        return_status_ok
      end

      def get_and_update_node_state!(node, attribute_names)
        pp [:get_and_update_node_state, node, attribute_names]
        node_info = Client.new('52.71.180.183').vm_info(node)
        pp [:node_info, node_info]
        fail ErrorUsage.new("got to get_and_update_node_state!")
      end

      def set_pbuilderid!(node)
        # TODO: write; put it in the external ref
      end

      def pbuilderid(node)
        InstanceId.node_id(node)
      end

      def destroy_node?(node, _opts = {})
        Log.info_pp(["Need to write Bosh#destroy_node?", node])
        true 
      end
    end
  end
end
