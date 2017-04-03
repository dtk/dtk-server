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
  module CommandAndControlAdapter
    class Ec2 < CommandAndControl::IAAS
      r8_nested_require('ec2', 'reified')
      r8_nested_require('ec2', 'client_token')
      r8_nested_require('ec2', 'node_state')
      r8_nested_require('ec2', 'address_management')
      #create_node must be below above three
      r8_nested_require('ec2', 'create_node')

      # TODO: can remove these mixins and put directly in this file
      extend NodeStateClassMixin
      extend AddressManagementClassMixin

      def self.execute(_task_idh, _top_task_idh, task_action)
        CreateNode.run(task_action)
      end

      def self.find_violations_in_target_service(target_service, params = {})
        Reified::Target.find_violations(target_service, params)
      end

      def self.find_violations_in_node_components(service, params = {})
        Reified::Node.find_violations(service, params)
      end

      def self.create_nodes_from_service(service, params = {})
        Reified::Node.create_nodes_from_service(service, params)
      end


      def self.node_property_legal_attributes
        Reified::Node.legal_attributes
      end

      DefaultRegion = 'us-east-1'

      def self.find_matching_node_binding_rule(node_binding_rules, target)
        node_binding_rules.find do |r|
          conditions = r[:conditions]
          (conditions[:type] == 'ec2_image') && (conditions[:region] == target[:iaas_properties][:region])
        end
      end

      def self.references_image?(node_external_ref)
        node_external_ref[:type] == 'ec2_image' && node_external_ref[:image_id]
      end

      def self.pbuilderid(node)
        if node.is_assembly_wide_node?()
          "docker-executor"
        else
          node.get_external_ref()[:instance_id]
        end
      end

      def self.start_instances(nodes)
        nodes.each do |node|
          aws_conn_from_node(node).server_start(node.instance_id())
          node.update_admin_op_status!(:pending) unless [:running, 'running'].include?(node.get_admin_op_status)
          Log.debug "Starting instance '#{node[:display_name]}', instance ID: '#{node.instance_id()}'"
        end
      end

      def self.stop_instances(nodes)
        donot_stop_nodes = nodes.select { |n| marked_donot_stop?(n) }
        unless donot_stop_nodes.empty?
          node_names = donot_stop_nodes.map { |n| n.get_field?(:display_name) }
          fail ErrorUsage.new("Cannot stop the nodes (#{node_names.join(',')})")
        end

        nodes.each do |node|
          aws_conn_from_node(node).server_stop(node.instance_id())
          node.update_admin_op_status!(:stopped)
          # we remove dns if it is not persistent dns
          unless node.persistent_hostname?
            node.strip_dns_info!()
          end
          Log.debug "Stopping instance '#{node[:display_name]}', instance ID: '#{node.instance_id()}'"
        end
      end

      # destroys the node if it exists
      def self.destroy_node?(node, opts = {})
        node.update_obj!(:external_ref, :hostname_external_ref)
        instance_id = external_ref(node)[:instance_id]
        return true unless instance_id #return if instance does not exist

        if marked_donot_delete?(node)
          return true
        end

        response = aws_conn_from_node(node).server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response}")
        process_addresses__terminate?(node)

        if opts[:reset]
          if response
            reset_node(node)
          end
        end
        response
      end

      # TODO: hacks to make sure dont delete or stop the router in multi temnant deploy
      def self.marked_donot_delete?(node)
        if instance_id = external_ref(node)[:instance_id]
          PerisistentIds.include?(instance_id)
        end
      end
      def self.marked_donot_stop?(node)
        marked_donot_delete?(node)
      end
      PerisistentIds =
        [
         'i-23666703' # dtk router
        ]

      def self.reset_node(node)
        update_hash = {
          external_ref: Aux.hash_subset(external_ref(node), ExternalRefPendingCols),
          type: 'staged',
          admin_op_status: 'pending',
          hostname_external_ref: nil
        }
        update_node!(node, update_hash)
      end
      private_class_method :reset_node
      ExternalRefPendingCols = [:image_id, :type, :size, :region]

      # we can provide this methods set of aws_creds that will be used. We will not use this
      # EC2 client as member, since this is only for this specific call
      def self.conn(credentials_with_region)
        CloudConnect::EC2.new(credentials_with_region)
      end

      def self.credentials_ok?(credentials_with_region)
        CloudConnect::EC2.credentials_ok?(credentials_with_region)
      end

      private

      # opts can have keys
      #  :reified_target
      def self.aws_conn_from_node(node, opts = {})
        reified_target = opts[:reified_target] || Reified::Target.create_from_node(node)
        Reified::Node.create_with_aws_conn(node, reified_target).aws_conn
      end


      def self.external_ref(node)
        node.get_field?(:external_ref) || {}
      end

      #########################
      # TODO: deprecate these below
      public

      def self.get_availability_zones(iaas_properties, region, opts = {})
        connection = opts[:connection] || get_connection_from_iaas_properties(iaas_properties, region)
        response = connection.describe_availability_zones
        fail ErrorUsage.new('Unable to retreive availability zones!') unless response.status == 200
        response.body['availabilityZoneInfo'].map { |z| z['zoneName'] } || []
      end

      # TODO: wil remove this
      def self.check_iaas_properties(iaas_properties, opts = {})
        ret = iaas_properties
        specified_region = iaas_properties[:region]
        region = specified_region || DefaultRegion
        connection = get_connection_from_iaas_properties(iaas_properties, region)
        # raise_error_if = RaiseErrorIf.new(iaas_properties, region, connection)

        # raise_error_if.invalid_credentials()

        # only do these checks if specified region
        unless specified_region
          return ret
        end
        (opts[:properties_to_check] || []).each do |property|
          case property
            when :subnet 
            # so can remove invalid_subnet
            # raise_error_if.invalid_subnet(iaas_properties[:subnet])
            else
            Log.error("Not supporting check of property '#{property}'")
          end
        end
        ret
      end

      private

      def self.get_ec2_credentials(iaas_credentials)
        if iaas_credentials && (aws_key = iaas_credentials['key'] || aws_key = iaas_credentials[:key]) && (aws_secret = iaas_credentials['secret'] || aws_secret = iaas_credentials[:secret])
          { aws_access_key_id: aws_key, aws_secret_access_key: aws_secret }
        end
      end

      def self.get_connection_from_iaas_properties(iaas_properties, region)
        ec2_creds = get_ec2_credentials(iaas_properties)
        conn(ec2_creds.merge(region: region))
      end
    end
  end
end
