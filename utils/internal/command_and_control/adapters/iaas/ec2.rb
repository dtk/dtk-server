module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      def self.execute(task_idh,top_task_idh,create_node,attributes_to_set)
        task_mh = task_idh.createMH()
        #handle case where node has been created already (and error mayu have been time out waiting for node to be up
        instance_id = ((create_node[:node]||{})[:external_ref]||{})[:instance_id]
        if instance_id.nil?
          ami = ((create_node[:image]||{})[:external_ref]||{})[:image_id]
          unless ami
            Log.error("cannot find ami")
            ami = "ami-2a4cb343" #TODO: stub
          end
          raise ErrorCannotCreateNode.new unless ami
          flavor_id = ((create_node[:image]||{})[:external_ref]||{})[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size] 
          create_options = {:image_id => ami,:flavor_id => flavor_id}

          #TODO: right now hardcoding groups
          create_options.merge!(:groups => ["basic"])
          response = conn().server_create(create_options)
          instance_id = response[:id]
          state = response[:state]
          external_ref = {
            :instance_id => instance_id,
            :type => "ec2_instance"
          }
          Log.info("node created with instance id #{instance_id}; waiting for it to be available")
          pp [:node_created,response]
          create_node[:node].merge!(:external_ref => external_ref)
          create_node.save_new_node_info(task_mh)
        else
          Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
        end
        wait_for_node_to_be_ready(create_node[:node])
        updated_server_state = conn().server_get(instance_id)
        pp [:updated_server_state,updated_server_state]
        Log.info("node #{instance_id} is available")

        #updete attributes
        updated_attributes = Array.new
        attributes_to_set.each do |attr|
          fn = AttributeToSetMapping[attr[:display_name]]
          unless fn
            Log.error("no rules to process attribute to set #{attr[:display_name]}")
            next
          end

          new_value = fn.call(updated_server_state)
          unless false #TODO: temp for testing attr[:value_asserted] == new_value
            attr[:value_asserted] = new_value
            updated_attributes << attr
          end
        end

        result = {:status => "succeeded",
          :node => {
            :external_ref => {
              :instance_id => instance_id,
              :type => "ec2_instance"
            }
          }
        }
        [result,updated_attributes]
      end
     private
      def self.wait_for_node_to_be_ready(node)
        CommandAndControl.wait_for_node_to_be_ready(node)
      end

      AttributeToSetMapping = {
        "host_addresses_ipv4" =>  lambda{|server|[server[:dns_name]]}
      }

      #TODO: sharing ec2 connection with ec2 datasource
      def self.conn()
        Conn[0] ||= CloudConnect::EC2.new
      end
      Conn = Array.new
    end
  end
end
