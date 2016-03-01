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
  module CommandAndControlAdapter; class Bosh
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
        @client      = Bosh::Client.new('52.71.180.183')
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
        pp [:bosh_client_info, @client.info]
##        pp [:bosh_deployment_vms, @client.deployment_vms(deployment_name)]
        manifest_yaml = DeploymentManifest.generate_yaml(self)
        deploy_result = @client.deploy(manifest_yaml)
        if bosh_task_id = deploy_result[:task_id]
          process = true
          count = 0
          while process
            count += 1
            task_result = @client.task(bosh_task_id)
            pp [:bosh_task, count, task_result, task_result['state']]
            sleep 2
            process = false if count > 10 or %w{error done}.include?(task_result['state'])
          end
        end
      end
    end
  end
end; end

