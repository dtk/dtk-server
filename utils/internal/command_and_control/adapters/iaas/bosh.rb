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
      r8_nested_require('bosh', 'node_id')

      def execute(_task_idh, top_task_idh, task_action)
        top_task_id = top_task_idh.get_id
        # Assumption is that all all task_action's actions associated with same top_task_id have same target
        target = task_action.target()
        create_nodes = CreateNodes.get_or_create(top_task_id, target)
        # task_action wil be either be to queue node or to execute
        # TODO: Stub that just assumes one node and does trigger outside of it
        # need to case on task_action
        create_nodes.queue(task_action)
        create_nodes.execute
        create_nodes.remove!(top_task_id)
        return_status_ok
      end

      def get_and_update_node_state!(node, attribute_names)
        pp [:get_and_update_node_state, node, attribute_names]
        fail ErrorUsage.new("got to get_and_update_node_state!")
      end

      def set_pbuilderid!(node)
        # TODO: write; put it in the external ref
      end

      def pbuilderid(node)
        NodeId.node_id(node)
      end

      def destroy_node?(node, _opts = {})
        Log.info_pp(["Need to write Bosh#destroy_node?", node])
        true 
      end
    end
  end
end
