module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      r8_nested_require('ec2','cloud_init')
      def self.find_matching_node_binding_rule(node_binding_rules,target)
        node_binding_rules.find do |r|
          conditions = r[:conditions]
          conditions[:region] == target[:iaas_properties][:region]
        end
      end

      def self.existing_image?(image_id)
        !!conn().image_get(image_id)
      end

      def self.start_instances(nodes)
        nodes.each do |node|
          conn().server_start(node.instance_id())
          node.update_admin_op_status!(:pending)
          Log.debug "Starting instance '#{node[:display_name]}', instance ID: '#{node.instance_id()}'"
        end
      end

      def self.stop_instances(nodes)
        nodes.each do |node|
          conn().server_stop(node.instance_id())
          node.update_admin_op_status!(:stopped)
          Log.debug "Stopping instance '#{node[:display_name]}', instance ID: '#{node.instance_id()}'"
        end
      end

      def self.associate_persistent_dns(node)
        node.update_object!(:hostname_external_ref, :admin_op_status, :external_ref)
        dns_name = node[:external_ref][:dns_name]
        # TODO: Link it to IP, need ot speak to reach to see how to get IP data
        # we add record to DNS which links node's DNS to perssistent DNS

        record = dns().get(node.persistent_dns())

        if record.nil?
          # there is no record we need to create it (first boot)
          record = dns().create(node.persistent_dns(),dns_name)
        else
          # we need to update it with new dns name
          record = record.modify(:value => dns_name)
        end

        # in case there was no record created we raise error
        raise Error, "Not able to set DNS hostname for node with ID '#{node[:id]}" if record.nil?

        # if all sucess we update the database
        node.update(
          :external_ref => node[:external_ref].merge(:dns_name => node.persistent_dns()),
          :hostname_external_ref => node[:hostname_external_ref].merge(:node_dns => dns_name),
          :admin_op_status       => "running"
        )

        Log.info "Persistent DNS '#{node.persistent_dns()}' has been assigned to node and set as default DNS."
      end

      def self.process_persistent_hostname__first_boot!(node)
        persistent_dns = dns().get_dns(node)

        # we create it on node ready since we still do not have that data
        node.update({
          :hostname_external_ref => {:persistent_dns => persistent_dns, :iaas => :aws },
          :admin_op_status       => 'pending'
        })
  
        Log.info("Persistent DNS needed for node '#{node[:display_name]}', assigned '#{persistent_dns}'")
      end

      def self.process_persistent_hostname__terminate(node)
        unless node[:hostname_external_ref].nil? 
          success = dns().destroy(node.persistent_dns())
    
          if success
            Log.info "Persistent DNS has been released '#{node.persistent_dns()}', node termination continues."
          else
            Log.warn "System was not able to release '#{node.persistent_dns()}', for node ID '#{node[:id]}' look into this."
          end
        else
          Log.warn "There is error in logic, persistent data not found on persistent node."
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
            raise Error.new("cannot find ami")
          end
          raise ErrorCannotCreateNode.new unless ami
          flavor_id = external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size] 
          create_options = {:image_id => ami,:flavor_id => flavor_id}

          create_options.merge!(:groups => external_ref[:security_group_set]||[R8::Config[:ec2][:security_group]])

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
          begin
            response = conn().server_create(create_options)
          rescue => e
            return {:status => "failed", :error_object => e}
          end
          instance_id = response[:id]
          state = response[:state]
          external_ref = external_ref.merge({
            :instance_id => instance_id,
            :type => "ec2_instance"
          })
          Log.info("#{node_print_form(node)} with ec2 instance id #{instance_id}; waiting for it to be available")
          node_update_hash = {
            :external_ref => external_ref,
            :type => "instance",
            :is_deployed => true,
            :operational_status => "starting"
          }
          node.merge!(node_update_hash)
          node.update(node_update_hash)
        else
          Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
        end
        if node.persistent_hostname?()
          process_persistent_hostname__first_boot!(node)
        end
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
        response = conn().server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response.to_s}")
        if node.persistent_hostname?()
          process_persistent_hostname__terminate(node)
        end
        response
      end

      def self.get_and_update_node_state!(node,attribute_names)
        ret = Hash.new
        instance_id = node.instance_id()
        unless instance_id
          Log.error("get_node_state called when #{node_print_form(node)} does not have instance id")
          return ret
        end
        raw_state_info = conn().server_get(instance_id)
        return ret unless raw_state_info
        #attribute_names in normalized form so need to convert
        change = nil
        attribute_names.each do |normalized_attr_name|
          if raw_info = AttributeToSetMapping[normalized_attr_name]
            raw_name = raw_info[:raw_name]
            raw_val = raw_state_info[raw_name]
            if normalized_val = (raw_info[:fn] ? raw_info[:fn].call(raw_state_info) : raw_val) 
              change = true
              ret[normalized_attr_name] = normalized_val
              node[:external_ref][raw_name] = raw_val
            end
          end
        end
        node.update(:external_ref => node[:external_ref]) if change
        ret
      end
      #TODO: if can legitimately have nil value then need to change update
      AttributeToSetMapping = {
        :host_addresses_ipv4 => {
          :raw_name => :dns_name,
          :fn => lambda{|raw|raw[:dns_name] && [raw[:dns_name]]} #null if no value
        },
        :fqdn => {
          :raw_name => :private_dns_name,
          :fn => lambda{|raw|raw[:dns_name] && raw[:private_dns_name] && {raw[:dns_name] => raw[:private_dns_name]}}
        }
      }

      def self.get_node_operational_status(node)
        instance_id = (node[:external_ref]||{})[:instance_id]
        unless instance_id
          Log.error("get_node_state called when #{node_print_form(node)} does not have instance id")
          return nil
        end
        #TODO: see if more targeted get to just get operational status
        state = conn().server_get(instance_id)
        op_status = state && state[:state]
        StateTranslation[op_status] || op_status
      end
      StateTranslation = {
        "pending" => "starting",
        "shutting-down" => "stopping"
      } 

      def self.node_print_form(node)
        "#{node[:display_name]} (#{node[:id]}"
      end

      Conn    = Array.new
      AwsDns = Array.new

      #TODO: sharing ec2 connection with ec2 datasource
      def self.conn()
        Conn[0] ||= CloudConnect::EC2.new
      end

      def self.dns()
        AwsDns[0] ||= CloudConnect::Route53.new
      end

    end
  end
end
