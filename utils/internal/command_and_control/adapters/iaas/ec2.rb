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

      def self.get_updated_attributes(task_action)
        node = task_action[:node]
        instance_id = (node[:external_ref]||{})[:instance_id]
        raise Error.new("get_updated_attributes called when #{node_print_form(node)} does not have instance id") unless instance_id
        attributes_to_set = task_action.attributes_to_set()
        updated_server_state = conn().server_get(instance_id)
        ret = Array.new
        attributes_to_set.each do |attr|
          unless fn = AttributeToSetMapping[attr[:display_name]]
            Log.error("no rules to process attribute to set #{attr[:display_name]}")
          else
            new_value = fn.call(updated_server_state)
            unless false #TODO: temp for testing attr[:value_asserted] == new_value
              unless new_value.nil?
                attr[:value_asserted] = new_value
                ret << attr
              end
            end
          end
        end
        ret
      end
     private

      #TODO: if can legitimately have nil value then need to change updtae
      AttributeToSetMapping = {
        "host_addresses_ipv4" =>  lambda{|server|(server||{})[:dns_name] && [server[:dns_name]]} #null if no value
      }
      
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
