module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS

      R8_KEY_PAIR = 'admin'

      r8_nested_require('ec2','cloud_init')
      r8_nested_require('ec2','node_state')
      r8_nested_require('ec2','address_management')
      extend NodeStateClassMixin
      extend AddressManagementClassMixin

      def self.find_matching_node_binding_rule(node_binding_rules,target)
        node_binding_rules.find do |r|
          conditions = r[:conditions]
          (conditions[:type] == "ec2_image") and (conditions[:region] == target[:iaas_properties][:region])
        end
      end

      def self.existing_image?(image_id)
        !!conn().image_get(image_id)
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

      def self.add_security_group_and_key_pair(iaas_credentials)
        begin
          ec2_creds = get_ec2_credentials(iaas_credentials)
          connection = conn(ec2_creds)
          connection.create_key_pair(R8::Config[:ec2][:keypair])
          Log.debug "Created needed R8 key pair (#{R8::Config[:ec2][:keypair]}) for newly created target-template"
          connection.create_security_group(R8::Config[:ec2][:security_group], 'DTK security group')
          Log.debug "Created needed security group (#{R8::Config[:ec2][:security_group]})  for newly created target-template"
        rescue Fog::Compute::AWS::Error => e
          # probabably this will handle credentials failure
          raise ErrorUsage.new(e.message)
        end
      end

      def self.execute(task_idh,top_task_idh,task_action)
        node = task_action[:node]
        node.update_object!(:os_type,:external_ref,:hostname_external_ref)

        external_ref = node[:external_ref]||{}
        instance_id = external_ref[:instance_id]

        if instance_id.nil?
          ami = external_ref[:image_id]
          unless ami
            node.update_object!(:display_name)
            raise ErrorUsage.new("Cannot find ami for node (#{node[:display_name]})")
          end

          flavor_id = external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size] 
          create_options = {:image_id => ami,:flavor_id => flavor_id}

          create_options.merge!(:groups => external_ref[:security_group_set]||[R8::Config[:ec2][:security_group]]||"default")

          # set the ec2 name tag
          ec2_name = "#{::DTK::Common::Aux.running_process_user()[0...127]}:#{node[:display_name][0...255]}"
          create_options.merge!(:tags => {"Name" => ec2_name})

          #TODO: fix up
          create_options.merge!(:key_name => R8::Config[:ec2][:keypair])
          avail_zone = R8::Config[:ec2][:availability_zone] || external_ref[:availability_zone]
          unless avail_zone.nil? or avail_zone == "automatic"
            create_options.merge!(:availability_zone => avail_zone)
          end
          #end fix up

          unless create_options.has_key?(:user_data)
            user_data = CloudInit.user_data(node[:os_type])
            create_options[:user_data] = user_data if user_data
          end
          response = nil

          # we check if assigned target has aws credentials assigned to it, if so we will use those
          # credentials to create nodes
          target_aws_creds = node.get_target_iaas_credentials()

          begin
            response = conn(target_aws_creds).server_create(create_options)
          rescue => e
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
            :type => "instance",
            :is_deployed => true,
            #TODO: better unify these below
            :operational_status => "starting",
            :admin_op_status => "pending"
          }
          node.merge!(node_update_hash) 
          node.update(node_update_hash)
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

#TODO: when put apt-get update in thing delying time it taks for the os to say it is ready /usr/bin/apt-get update
      #destroys the node if it exists
      def self.destroy_node?(node)
        instance_id = (node[:external_ref]||{})[:instance_id]
        return true unless instance_id #return if instance does not exist

        target_aws_creds = node.get_target_iaas_credentials()

        response = conn(target_aws_creds).server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response.to_s}")
        process_addresses__terminate?(node)
        response
      end

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
        return nil
      end

    end
  end
end
