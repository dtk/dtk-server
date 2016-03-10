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
      r8_nested_require('bosh', 'bosh_subnet')
      r8_nested_require('bosh', 'param')

      def execute(_task_idh, top_task_idh, task_action)
        top_task = top_task_idh.create_object()
        # Assumption is that all all task_action's actions associated with same top_task_id have same target
        target = task_action.target()
        create_nodes = CreateNodes.get_or_create(top_task, target)
        create_nodes.queue(task_action)
        if task_action[:initiate_create_nodes]
          create_nodes.dispatch_bosh_deployment
        end
        return_status_ok
      end

      def get_node_operational_status(_node)
        # TODO: stub
        'running'
      end

      # TODO: unify with ec2's et_and_update_node_state! method
      def get_and_update_node_state!(node, attribute_names)
        ret = {}
        external_ref = node[:external_ref]
        external_ref_changed = false
        if attribute_names.include?(:host_addresses_ipv4)
          if host_addresses_ipv4 = Client.new.vm_info(node).host_addresses_ipv4
            Log.info("Info from BOSH Director: node '#{node.get_field?(:display_name)}' with id '#{node.id}' has host addresses: #{host_addresses_ipv4.join(', ')}")
          end
          host_addresses_ipv4 = Client.new.vm_info(node).host_addresses_ipv4
          # TODO: need to get away from using ec2_public_address
          external_ref[:ec2_public_address] = external_ref[:dns_name] = host_addresses_ipv4
          ret.merge!(host_addresses_ipv4: host_addresses_ipv4)
          external_ref_changed = true
        end
#        other =  attribute_names - [:host_addresses_ipv4]
#        unless other.empty?
#          Log.error("Not treating update of BOSH node attributes: #{other.join(', ')}")
#        end
        node.update(external_ref: external_ref) if external_ref_changed
        ret        
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
