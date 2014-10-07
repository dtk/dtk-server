module DTK
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      R8_KEY_PAIR = 'admin'

      r8_nested_require('ec2','node_state')
      r8_nested_require('ec2','address_management')
      r8_nested_require('ec2','image')
      #create_node must be below above three
      r8_nested_require('ec2','create_node')

      extend NodeStateClassMixin
      extend AddressManagementClassMixin
      extend ImageClassMixin

      def self.execute(task_idh,top_task_idh,task_action)
        CreateNode.run(task_action)
      end

      def self.find_matching_node_binding_rule(node_binding_rules,target)
        node_binding_rules.find do |r|
          conditions = r[:conditions]
          (conditions[:type] == "ec2_image") and (conditions[:region] == target[:iaas_properties][:region])
        end
      end

      def self.references_image?(node_external_ref)
        node_external_ref[:type] == "ec2_image" and node_external_ref[:image_id]
      end

      def self.existing_image?(image_id,target)
        image(image_id,:target => target).exists?()
      end

      def self.raise_error_if_invalid_image?(image_id,target)
        unless existing_image?(image_id,target)
          err_msg = "Image (#{image_id}) is not accessible from target #{target.get_field?(:display_name)}"
          if region = target.iaas_properties.hash()[:region]
            err_msg << " (ec2: #{region})"
          end
          raise ErrorUsage.new(err_msg)
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

      def self.get_availability_zones(iaas_properties)
        ec2_creds = get_ec2_credentials(iaas_properties)
        connection = conn(ec2_creds)

        response = connection.describe_availability_zones
        raise ErrorUsage.new("Unable to retreive availability zones!") unless response.status == 200

        a_zones = response.body["availabilityZoneInfo"].map{|z| z['zoneName']}||[]
      end

      def self.check_iaas_properties(iaas_properties)
        begin
          ec2_creds = get_ec2_credentials(iaas_properties)
          connection = conn(ec2_creds)

          # keypair
          keypair_to_use = iaas_properties['keypair_name'] || R8::Config[:ec2][:keypair]
          # TODO: WORKAROUND: DTK-1426; commented out
          # connection.check_for_key_pair(keypair_to_use)
          
          Log.debug "Fetched needed R8 key pair (#{keypair_to_use}) for newly created target-template. (Default used: #{!iaas_properties['keypair_name'].nil?})"

          # security group
          security_group_set_to_use = iaas_properties['security_group_set']
          security_group_to_use = iaas_properties['security_group'] || R8::Config[:ec2][:security_group]
          # TODO: WORKAROUND: DTK-1426; commented out
          # connection.check_for_security_group(security_group_to_use)

          Log.debug "Fetched needed security group (#{security_group_to_use})  for newly created target-template. (Default used: #{!iaas_properties['security_group'].nil?})"
          ret_hash = {
            :key            => iaas_properties['key'],
            :secret         => iaas_properties['secret'],
            :keypair        => keypair_to_use,
            # :security_group => security_group_to_use,
            :region         => iaas_properties['region']
          }

          if security_group_set_to_use
            ret_hash.merge!(:security_group_set => security_group_set_to_use)
          else
            ret_hash.merge!(:security_group => security_group_to_use)
          end

          ret_hash
        rescue Fog::Compute::AWS::Error => e
          # probabably this will handle credentials failure
          raise ErrorUsage.new(e.message)
        end
      end

      def self.get_ec2_credentials(iaas_credentials)
        if iaas_credentials && (aws_key = iaas_credentials['key'] || aws_key = iaas_credentials[:key]) && (aws_secret = iaas_credentials['secret'] || aws_secret = iaas_credentials[:secret])
          { :aws_access_key_id => aws_key, :aws_secret_access_key => aws_secret }
        end
      end
      private_class_method :get_ec2_credentials

      # destroys the node if it exists
      def self.destroy_node?(node,opts={})
        node.update_obj!(:external_ref,:hostname_external_ref) 
        instance_id = external_ref(node)[:instance_id]
        return true unless instance_id #return if instance does not exist

        target_aws_creds = node.get_target_iaas_credentials()

        response = conn(target_aws_creds).server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response.to_s}")
        process_addresses__terminate?(node)

        if opts[:reset]
          if response
            reset_node(node)
          end
        end
        response
      end

      def self.reset_node(node)
        update_hash = {
          :external_ref => Aux.hash_subset(external_ref(node),ExternalRefPendingCols),
          :type => 'staged',
          :admin_op_status => 'pending',
          :hostname_external_ref => nil
        }
        update_node!(node,update_hash)
      end
      private_class_method :reset_node
      ExternalRefPendingCols = [:image_id,:type,:size,:region]

      def self.target_non_default_aws_creds?(target)
        iaas_prop_hash = target.iaas_properties.hash()
        region = iaas_prop_hash[:region]
        unless target.is_builtin_target?()
          if region
            CloudConnect::EC2.new.get_compute_params().merge(:region => region)
          else
            unless iaas_prop_hash[:key] and iaas_prop_hash[:secret]
              raise Error.new("Unexpected that no builtin target does not have needed fields")
              ret = {
                :aws_access_key_id => iaas_prop_hash[:key],
                :aws_secret_access_key => iaas_prop_hash[:secret]
              }
              ret.merge!(:region => region) if region
              ret
            end
          end
        end
      end

      # we can provide this methods set of aws_creds that will be used. We will not use this
      # EC2 client as member, since this is only for this specific call
      def self.conn(target_aws_creds=nil)
        if target_aws_creds
          return CloudConnect::EC2.new(target_aws_creds)
        end

        @conn ||= CloudConnect::EC2.new
      end

     private

      def self.update_node!(node,update_hash)
        node.merge!(update_hash) 
        node.update(update_hash)
        node
      end

      def self.external_ref(node)
        node.get_field?(:external_ref)||{}
      end

    end
  end
end
