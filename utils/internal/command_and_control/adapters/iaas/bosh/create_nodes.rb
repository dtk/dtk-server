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

      def self.get_or_create(top_task, target)
        top_task_list_add!(top_task, target)
      end

      NodeInfo = Struct.new(:node, :base_node)
      def initialize(top_task_idh, target)
        @top_task_idh  = top_task_idh
        @target       = target 
        @bosh_client  = Bosh::Client.new
        @node_objects = [] # Array of NodeInfo
      end
      private :initialize

      def queue(task_action)
        base_node = task_action.base_node()
        nodes = task_action.nodes.each do |node|
          node.update_object!(:external_ref, :assembly_id)
          @node_objects << NodeInfo.new(node, base_node)
        end
      end

      ReleaseName = 'dtk-agent'
      def dispatch_bosh_deployment
        # TODO: stub; nailed deployment_name
        deployment_name = 'dtk'
        unless version_obj = @bosh_client.latest_release_version?(ReleaseName)
          fail ErrorUsage.new("BOSH release '#{ReleaseName}' does not exist")
        end
        version = version_obj.version
        Log.info("Using BOSH release '#{version}'")
        deployment_params = {
          director_uuid: @bosh_client.director_uuid,
          release: { name: ReleaseName, version: version },
          deployment_name: deployment_name,
          job_objects: job_objects,
        }
        manifest_yaml = DeploymentManifest.generate_yaml(deployment_params)
        deploy_task = @bosh_client.deploy(manifest_yaml)
        if error_msg = deploy_task.error?
          fail ErrorUsage.new(error_msg)
        end
        @node_objects.each { |node_obj| update_node_from_create_node!(node_obj, deployment_name) }
        top_task_list_remove!
        fail ErrorUsage.new("got here")

      end

      private

      def update_node_from_create_node!(node_obj, deployment_name)
        node = node_obj.node
        base_node = node_obj.base_node
        update_params = {
          base_node: base_node,
          external_ref: node.get_field?(:external_ref)
        }
        instance_id = InstanceId.compute_instance_id(node, deployment_name)
#        Bosh.update_node_from_create_node!(node, 'bosh_instance', instance_id, update_params) # TODO: use a constant rather than 'bosh_instance'
      end

      JobObject = Struct.new(:name, :instances)
      def job_objects
        ndx_job_instances = {}
        @node_objects.each do |node_obj|
          node = node_obj.node
          job, index = InstanceId.bosh_job_and_index(node)
          count = ndx_job_instances[job] ||= 1
          ndx_job_instances[job] = index + 1 if index >= count 
        end
        ret = []
        ndx_job_instances.each_pair { |name, instances| ret << JobObject.new(name, instances) }
        ret
      end

      def self.top_task_list_add!(top_task, target)
        top_task_id = top_task.id
        (@@active_tasks ||= {})[top_task_id] || @@active_tasks[top_task_id] = new(top_task.id_handle, target)
      end

      def top_task_list_remove!
        (@@active_tasks ||= {}).delete(top_task_id)
      end

      def top_task_id
        @top_task_idh.get_id
      end

    end
  end
end; end

