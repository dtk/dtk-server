module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      r8_nested_require('ec2','cloud_init')
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
      def self.associate_elastic_ip(node)
        node.update_object!(:hostname_external_ref, :admin_op_status)
        conn().associate_elastic_ip(node.instance_id(),node.elastic_ip())
        node.update_admin_op_status!(:running)
      end

      def self.process_addresses__first_boot?(node)
        hostname_external_ref = {:iaas => :aws }
        if node.persistent_hostname?()
          begin 
            # allocate elastic IP for this node
            elastic_ip = conn().allocate_elastic_ip()
            hostname_external_ref.merge!(:elastic_ip => elastic_ip)
            Log.info("Persistent hostname needed for node '#{node[:display_name]}', assigned #{elastic_ip}")
           rescue Fog::Compute::AWS::Error => e
            Log.error "Not able to set Elastic IP, reason: #{e.message}"
          # TODO: Check with Rich if this is recovarable error, for now it is not
            raise e
          end
        end
        if dns_assignment = DNS::R8.generate_node_assignment?(node)
          persistent_dns = dns_assignment.address()
          
          # we create it on node ready since we still do not have that data
          hostname_external_ref.merge!(:persistent_dns => persistent_dns)
          Log.info("Persistent DNS needed for node '#{node[:display_name]}', assigned '#{persistent_dns}'")
        end
        node.update(:hostname_external_ref => hostname_external_ref)
      end

      def self.process_persistent_hostname__restart(node)
        Log.info("in process_persistent_hostname__restart for node #{node[:display_name]}")
        #TODO: stub for feature_node_admin_state
      end

      def self.process_addresses__terminate?(node)
        unless node[:hostname_external_ref].nil? 
          if node.persistent_hostname?()
            elastic_ip = node[:hostname_external_ref][:elastic_ip]
            # no need for dissasociation since that will be done when instance is destroyed
            conn().release_elastic_ip(elastic_ip)
            Log.info "Elastic IP #{elastic_ip} has been released."
          end
          
          if persistent_dns = node.persistent_dns()
            success = dns().destroy_record(persistent_dns)
            if success
              Log.info "Persistent DNS has been released '#{node.persistent_dns()}', node termination continues."
            else
              Log.warn "System was not able to release '#{node.persistent_dns()}', for node ID '#{node[:id]}' look into this."
            end
          else
            Log.warn "There is error in logic, elastic_ip data not found on persistent node."
          end
        end
      end

      def self.associate_persistent_dns?(node)
        node.update_object!(:hostname_external_ref, :admin_op_status, :external_ref)
        unless persistent_dns = node.persistent_dns()
          return
        end
        ec2_address = node[:external_ref][:ec2_public_address]
        # we add record to DNS which links node's DNS to perssistent DNS
        record = dns().get_record(node.persistent_dns())

        if record.nil?
          # there is no record we need to create it (first boot)
          record = dns().create_record(node.persistent_dns(),ec2_address)
        else
          # we need to update it with new dns name
          record = dns().update_record(record,ec2_address)
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
        response = conn().server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response.to_s}")
          process_addresses__terminate?(node)
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

      def self.conn()
        Conn[0] ||= CloudConnect::EC2.new
      end

      def self.dns()
        AwsDns[0] ||= CloudConnect::Route53.new(::R8::Config[:dns][:r8][:domain])
      end

    end
  end
end
