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
module DTK; class CommandAndControl::IAAS
  class Bosh
    class CreateNodes
      r8_nested_require('create_nodes', 'deployment_manifest')

      def self.get_or_create(top_task_id, target)
        (@@active_tasks ||= {})[top_task_id] || @@active_tasks[top_task_id] = new(top_task_id, target)
      end

      def remove!(top_task_id)
        @@active_tasks.delete(top_task_id)
      end

      NodeInfo = Struct.new(:node, :index, :base_node)
      def initialize(top_task_id, target)
        @top_task_id = top_task_id
        @target      = target 
        @bosh_client      = Bosh::Client.new('52.71.180.183')
        @node_objects       = [] # Array of NodeInfo
      end
      private :initialize

      def queue(task_action)
        base_node = task_action.base_node()
        nodes = task_action.nodes.each_with_index do |node, index|
          node.update_object!(:external_ref, :assembly_id)
          @node_objects << NodeInfo.new(node, index, base_node)
        end
      end

      def execute
        deployment_name = 'dtk'
        release_name = 'dtk-agent'
        unless version_obj = @bosh_client.latest_release_version?(release_name)
          fail ErrorUsage.new("BOSH release '#{release_name}' does not exist")
        end
        pp [:version_obj, version_obj]
        deployment_params = {
          director_uuid: @bosh_client.director_uuid,
          release: { name: release_name, version: version_obj.version },
          deployment_name: deployment_name,
          instances: @node_objects.size,
        }
        manifest_yaml = DeploymentManifest.generate_yaml(deployment_params)
        deploy_task = @bosh_client.deploy(manifest_yaml)
        if error_msg = deploy_task.error?
          fail ErrorUsage.new(error_msg)
        end
        @node_objects.each { |node_obj| update_node_from_create_node!(node_obj, deployment_name) }
      end

      def update_node_from_create_node!(node_obj, deployment_name)
        node = node_obj.node
        base_node = node_obj.base_node
        update_params = {
          base_node: base_node,
          external_ref: node.get_field?(:external_ref)
        }
        group_name = node.get_field?(:display_name).gsub(/:[0-9]+$/,'') # TODO: use standard fns to do this
        pp [:group_name, group_name, node_obj.index]
        instance_id = InstanceId.compute_instance_id(group_name, node_obj.index, deployment_name)
        Bosh.update_node_from_create_node!(node, 'bosh_instance', instance_id, update_params) # TODO: use a constant rather than 'bosh_instance'
      end
    end
  end
end; end

