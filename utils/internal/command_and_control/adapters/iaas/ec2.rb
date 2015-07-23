module DTK
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      r8_nested_require('ec2', 'client_token')
      r8_nested_require('ec2', 'node_state')
      r8_nested_require('ec2', 'address_management')
      r8_nested_require('ec2', 'image')
      #create_node must be below above three
      r8_nested_require('ec2', 'create_node')

      extend NodeStateClassMixin
      extend AddressManagementClassMixin
      extend ImageClassMixin

      def self.execute(_task_idh, _top_task_idh, task_action)
        CreateNode.run(task_action)
      end

      def self.find_matching_node_binding_rule(node_binding_rules, target)
        node_binding_rules.find do |r|
          conditions = r[:conditions]
          (conditions[:type] == 'ec2_image') && (conditions[:region] == target[:iaas_properties][:region])
        end
      end

      def self.references_image?(node_external_ref)
        node_external_ref[:type] == 'ec2_image' && node_external_ref[:image_id]
      end

      def self.existing_image?(image_id, target)
        image(image_id, target: target).exists?()
      end

      def self.raise_error_if_invalid_image?(image_id, target)
        unless existing_image?(image_id, target)
          err_msg = "Image (#{image_id}) is not accessible from target #{target.get_field?(:display_name)}"
          if region = target.iaas_properties.hash()[:region]
            err_msg << " (ec2: #{region})"
          end
          fail ErrorUsage.new(err_msg)
        end
      end

      def self.pbuilderid(node)
        node.get_external_ref()[:instance_id]
      end

      def self.start_instances(nodes)
        nodes.each do |node|
          conn(node.get_target_iaas_credentials()).server_start(node.instance_id())
          node.update_admin_op_status!(:pending)
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
          conn(node.get_target_iaas_credentials()).server_stop(node.instance_id())
          node.update_admin_op_status!(:stopped)
          # we remove dns if it is not persistent dns
          unless node.persistent_hostname?
            node.strip_dns_info!()
          end
          Log.debug "Stopping instance '#{node[:display_name]}', instance ID: '#{node.instance_id()}'"
        end
      end

      def self.get_availability_zones(iaas_properties, region, opts = {})
        connection = opts[:connection] || get_connection_from_iaas_properties(iaas_properties, region)
        response = connection.describe_availability_zones
        fail ErrorUsage.new('Unable to retreive availability zones!') unless response.status == 200
        response.body['availabilityZoneInfo'].map { |z| z['zoneName'] } || []
      end

      def self.check_iaas_properties(iaas_properties, opts = {})
        ret = iaas_properties
        specified_region = iaas_properties[:region]
        region = specified_region || DefaultRegion
        connection = get_connection_from_iaas_properties(iaas_properties, region)
        raise_error_if = RaiseErrorIf.new(iaas_properties, region, connection)

        raise_error_if.invalid_credentials()

        # only do these checks if specified region
        unless specified_region
          return ret
        end
        (opts[:properties_to_check] || []).each do |property|
          case property
            when :subnet then raise_error_if.invalid_subnet(iaas_properties[:subnet])
            else
            Log.error("Not supporting check of property '#{property}'")
          end
        end
        ret
      end
      DefaultRegion = 'us-east-1'

      def self.get_connection_from_iaas_properties(iaas_properties, region)
        ec2_creds = get_ec2_credentials(iaas_properties)
        conn(ec2_creds.merge(region: region))
      end
      private_class_method :get_connection_from_iaas_properties

      class RaiseErrorIf
        def initialize(iaas_properties, region, connection)
          @iaas_properties = iaas_properties
          @region          = region
          @connection      = connection
        end

        def invalid_credentials
          Ec2.get_availability_zones(@iaas_properties, @region, connection: @connection)
         rescue => e
          Log.info_pp(['Error_from get_availability_zones', e])
          raise ErrorUsage.new('Invalid EC2 credentials')
        end

        def invalid_subnet(subnet)
          if subnet
            @connection.check_for_subnet(subnet)
          end
        end
      end

      def self.get_ec2_credentials(iaas_credentials)
        if iaas_credentials && (aws_key = iaas_credentials['key'] || aws_key = iaas_credentials[:key]) && (aws_secret = iaas_credentials['secret'] || aws_secret = iaas_credentials[:secret])
          { aws_access_key_id: aws_key, aws_secret_access_key: aws_secret }
        end
      end
      private_class_method :get_ec2_credentials

      # destroys the node if it exists
      def self.destroy_node?(node, opts = {})
        node.update_obj!(:external_ref, :hostname_external_ref)
        instance_id = external_ref(node)[:instance_id]
        return true unless instance_id #return if instance does not exist

        if marked_donot_delete?(node)
          return true
        end

        target_aws_creds = node.get_target_iaas_credentials()

        response = conn(target_aws_creds).server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response}")
        process_addresses__terminate?(node)

        if opts[:reset]
          if response
            reset_node(node)
          end
        end
        response
      end

      # TODO: hacks to make sure dont delete or stop the router
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
         'i-23666703' #dtk router
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

      def self.target_non_default_aws_creds?(target)
        iaas_prop_hash = target.iaas_properties
        iaas_prop_hash = iaas_prop_hash.is_a?(Hash) ? iaas_prop_hash : iaas_prop_hash.hash()
        region = iaas_prop_hash[:region]

        params = target.get_aws_compute_params
        params.merge!(region: region) if params
        params
      end

      # we can provide this methods set of aws_creds that will be used. We will not use this
      # EC2 client as member, since this is only for this specific call
      def self.conn(target_aws_creds = nil)
        if target_aws_creds
          return CloudConnect::EC2.new(target_aws_creds)
        end

        @conn ||= CloudConnect::EC2.new
      end

      private

      def self.update_node!(node, update_hash)
        node.merge!(update_hash)
        node.update(update_hash)
        node
      end

      def self.external_ref(node)
        node.get_field?(:external_ref) || {}
      end
    end
  end
end
