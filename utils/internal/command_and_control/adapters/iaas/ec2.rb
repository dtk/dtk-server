module DTK
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS

      R8_KEY_PAIR = 'admin'

      r8_nested_require('ec2','node_state')
      r8_nested_require('ec2','address_management')
      r8_nested_require('ec2','image')
      extend NodeStateClassMixin
      extend AddressManagementClassMixin
      extend ImageClassMixin

      def self.find_matching_node_binding_rule(node_binding_rules,target)
        node_binding_rules.find do |r|
          conditions = r[:conditions]
          (conditions[:type] == "ec2_image") and (conditions[:region] == target[:iaas_properties][:region])
        end
      end

      def self.references_image?(node_external_ref)
        node_external_ref[:type] == "ec2_image" and node_external_ref[:image_id]
      end

      def self.existing_image?(image_id)
        raise Error.new("existing_image does not take target region as param")
        image(image_id).exists?()
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
          security_group_to_use = iaas_properties['security_group'] || R8::Config[:ec2][:security_group]
          # TODO: WORKAROUND: DTK-1426; commented out
          # connection.check_for_security_group(security_group_to_use)

          Log.debug "Fetched needed security group (#{security_group_to_use})  for newly created target-template. (Default used: #{!iaas_properties['security_group'].nil?})"

          return {
            :key            => iaas_properties['key'],
            :secret         => iaas_properties['secret'],
            :keypair        => keypair_to_use,
            :security_group => security_group_to_use,
            :region         => iaas_properties['region']
          }
        rescue Fog::Compute::AWS::Error => e
          # probabably this will handle credentials failure
          raise ErrorUsage.new(e.message)
        end
      end

      def self.execute(task_idh,top_task_idh,task_action)

        node = task_action[:node]
pp [:node_group_debug,task_action.nodes()]
        node.update_object!(:os_type,:external_ref,:hostname_external_ref,:display_name,:assembly_id)

        target = Target.get(node.model_handle(:target), task_action[:datacenter][:id])

        external_ref = node[:external_ref]||{}
        instance_id = external_ref[:instance_id]

        if instance_id.nil?
          ami = external_ref[:image_id]
          unless ami
            node.update_object!(:display_name)
            raise ErrorUsage.new("Cannot find ami for node (#{node[:display_name]})")
          end

          flavor_id = external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size]
          block_device_mapping_from_image = image(ami).block_device_mapping_with_delete_on_termination()
          create_options = {:image_id => ami,:flavor_id => flavor_id }
          # only add block_device_mapping if it was fully generated
          create_options.merge!({ :block_device_mapping => block_device_mapping_from_image }) if block_device_mapping_from_image
          # check priority for security group
          security_group = target.get_security_group() || external_ref[:security_group_set]||[R8::Config[:ec2][:security_group]]||"default"
          create_options.merge!(:groups => security_group )

          create_options.merge!(:tags => {"Name" => ec2_name_tag(node, target)})

          # check priority of keypair
          keypair = target.get_keypair_name() || R8::Config[:ec2][:keypair]

          create_options.merge!(:key_name => keypair)
          avail_zone = R8::Config[:ec2][:availability_zone] || external_ref[:availability_zone]

          unless avail_zone.nil? or avail_zone == "automatic"
            create_options.merge!(:availability_zone => avail_zone)
          end
          # end fix up

          unless create_options.has_key?(:user_data)
            if user_data = CommandAndControl.install_script(node)
              create_options[:user_data] = user_data
            end
          end

          if root_device_size = node.attribute.root_device_size()
            if device_name = image(ami).block_device_mapping_device_name()
              create_options[:block_device_mapping].first.merge!({'DeviceName' => device_name, 'Ebs.VolumeSize' => root_device_size})
            else
              Log.error("Cannot determine device name for ami (#{ami})")
            end
          end

          response = nil

          # we check if assigned target has aws credentials assigned to it, if so we will use those
          # credentials to create nodes
          target_aws_creds = node.get_target_iaas_credentials()

          begin
            response = Ec2.conn(target_aws_creds).server_create(create_options)
          rescue => e
            # append region to error message
            region = target.get_region() if target
            e.message << ". Region: '#{region}'." if region

            Log.error_pp([e,e.backtrace[0..10]])
            return {:status => "failed", :error_object => e}
          end
          instance_id = response[:id]
          state = response[:state]
          external_ref = external_ref.merge({
            :instance_id => instance_id,
            :type => "ec2_instance",
            :size => flavor_id
          })
          Log.info("#{node_print_form(node)} with ec2 instance id #{instance_id}; waiting for it to be available")
          node_update_hash = {
            :external_ref => external_ref,
            :type => Node::Type::Node.instance,
            :is_deployed => true,
            # TODO: better unify these below
            :operational_status => "starting",
            :admin_op_status => "pending"
          }
          update_node!(node,node_update_hash)
        else
          Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
        end

        process_addresses__first_boot?(node)

        {:status => "succeeded",
          :node => {
            :external_ref => external_ref
          }
        }
      end

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

      def self.node_print_form(node)
        "#{node[:display_name]} (#{node[:id]}"
      end

      # we can provide this methods set of aws_creds that will be used. We will not use this
      # EC2 client as member, since this is only for this specific deployment
      def self.conn(target_aws_creds=nil)
        if target_aws_creds
          return CloudConnect::EC2.new(target_aws_creds)
        end

        @conn ||= CloudConnect::EC2.new
      end

     private
      def self.get_ec2_credentials(iaas_credentials)
        if iaas_credentials && (aws_key = iaas_credentials['key']) && (aws_secret = iaas_credentials['secret'])
          return { :aws_access_key_id => aws_key, :aws_secret_access_key => aws_secret }
        end
      end

      def self.update_node!(node,update_hash)
        node.merge!(update_hash) 
        node.update(update_hash)
        node
      end

      def self.external_ref(node)
        node.get_field?(:external_ref)||{}
      end

      def self.ec2_name_tag(node, target)
        assembly = node.get_assembly?()
        # TO-DO: move the tenant name definition to server configuration
        tenant = ::DtkCommon::Aux::running_process_user()
        subs = {
          :assembly => assembly && assembly.get_field?(:display_name),
          :node     => node.get_field?(:display_name),
          :tenant   => tenant,
          :target   => target[:display_name],
          :user     => CurrentSession.get_username()
        }
        ret = Ec2NameTag[:tag].dup
        Ec2NameTag[:vars].each do |var|
          val = subs[var]||var.to_s.upcase
          ret.gsub!(Regexp.new("\\$\\{#{var}\\}"),val)
        end
        ret
      end
      Ec2NameTag = {
        :vars => [:assembly, :node, :tenant, :target, :user],
        :tag => R8::Config[:ec2][:name_tag][:format]
      }
    end
  end
end
