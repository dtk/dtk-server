module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      def self.execute(task_idh,top_task_idh,task_action)
        node = task_action[:node]
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

          create_options.merge!(:groups => external_ref[:security_group_set]||DefaultSecurityGroupSet)
          #TODO: patch
          create_options.merge!(:key_name => "rich-east")
          avail_zone = external_ref[:availability_zone]
          unless avail_zone.nil? or avail_zone == "automatic"
            create_options.merge!(:availability_zone => avail_zone)
          end
          response = conn().server_create(create_options)
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
            :operational_status => "being_powered_on"
          }
          node.merge!(node_update_hash)
          node.update(node_update_hash)
        else
          Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
        end
        {:status => "succeeded",
          :node => {
            :external_ref => external_ref
          }
        }
      end
      DefaultSecurityGroupSet = ["default"] 
      #destroys the node if it exists
      def self.destroy_node?(node)
        instance_id = (node[:external_ref]||{})[:instance_id]
        return true unless instance_id #return if instance does not exist
        response = conn().server_destroy(instance_id)
        Log.info("operation to destroy ec2 instance #{instance_id} had response: #{response.to_s}")
        response
      end

      def self.get_node_state(node)
        instance_id = (node[:external_ref]||{})[:instance_id]
        raise Error.new("get_node_state called when #{node_print_form(node)} does not have instance id") unless instance_id
        conn().server_get(instance_id)
      end

      def self.node_print_form(node)
        "#{node[:display_name]} (#{node[:id]}"
      end

      #TODO: sharing ec2 connection with ec2 datasource
      def self.conn()
        Conn[0] ||= CloudConnect::EC2.new
      end
      Conn = Array.new
    end
  end
end
