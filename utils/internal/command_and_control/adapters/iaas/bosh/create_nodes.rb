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
  class CommandAndControl::IAAS; class Bosh
    class CreateNodes
      r8_nested_require('create_nodes', 'deployment_manifest')

      def self.get_or_create(top_task_id, target)
        (@@active_tasks ||= {})[top_task_id] || @@active_tasks[top_task_id] = new(top_task_id, target)
      end

      def remove!(top_task_id)
        @@active_tasks.delete(top_task_id)
      end

      NodeInfo = Struct.new(:node, :base_node)
      def initialize(top_task_id, target)
        @top_task_id = top_task_id
        @target      = target 
        @bosh_client      = Bosh::Client.new('52.71.180.183')
        @nodes       = [] # Array of NodeInfo
      end
      private :initialize

      def queue(task_action)
        base_node = task_action.base_node()
        nodes = task_action.nodes.each do |node|
          node.update_object!(:external_ref, :assembly_id)
          @nodes << NodeInfo.new(node, base_node)
        end
      end

      def execute
        deployment_name = 'dtk'
        pp [:bosh_client_info, @bosh_client.info]
##        pp [:bosh_deployment_vms, @bosh_client.deployment_vms(deployment_name)]
        manifest_yaml = DeploymentManifest.generate_yaml(director_uuid: @bosh_client.director_uuid)
        deploy_result = @bosh_client.deploy(manifest_yaml)
        if bosh_task_id = deploy_result[:task_id]
          steady_state = @bosh_client.poll_task_until_steady_state(bosh_task_id)
          if error_msg = steady_state.error?
            fail ErrorUsage.new(error_msg)
          end
        end
      end
    end
  end; end
end

