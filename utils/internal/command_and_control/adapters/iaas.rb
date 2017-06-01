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
  class CommandAndControl
    class IAAS < self
      DEFAULT_COMMUNICATION_ID = 'docker-executor'
      def self.pbuilderid(node)
        if node.is_assembly_wide_node?
          DEFAULT_COMMUNICATION_ID
        else
          NodeComponent.instance_id(node)
        end
      end

      # TODO: DTK-2938: check which of below should be removed
      # This should be overwritten
      def get_and_update_node_state!(_node, _attribute_names)
        fail Error.new("The method '#{self.class}#get_and_update_node_state' should be defined")
      end

      def self.node_print_form(node)
        "#{node[:display_name]} (#{node[:id]})"
      end

      def return_status_ok
        self.class.return_status_ok
      end
      def self.return_status_ok
        { status: 'succeeded' }
      end


      # param keys are
      #  base_node, 
      #  external_ref
      #  iaas_specfic_params (hash - optional)
      def self.update_node_from_create_node!(node, iaas_type, instance_id, params = {})
        eref_update_hash = {instance_id: instance_id, type: iaas_type}.merge(params[:iaas_specfic_params] || {})
        updated_external_ref = (params[:external_ref] || {}).merge(eref_update_hash)
        
        Log.info("#{node_print_form(node)} with ec2 instance id #{instance_id}; waiting for it to be available")
        node_update_hash = {
          external_ref: updated_external_ref,
          type: Node::Type.new_type_when_create_node(params[:base_node]),
          is_deployed: true,
          # TODO: better unify these below
          operational_status: 'starting',
          admin_op_status: 'pending'
        }
        update_node!(node, node_update_hash)
      end

      def self.update_node!(node, update_hash)
        node.merge!(update_hash)
        node.update(update_hash)
        node
      end
    end
  end
end

