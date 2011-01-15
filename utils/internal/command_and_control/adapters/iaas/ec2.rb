module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      def self.execute(create_node,attributes_to_set)
        #handle case where node has been created already (and error mayu have been time out waiting for node to be up
        instance_id = ((create_node[:node]||{})[:external_ref]||{})[:instance_id]
        if instance_id.nil?
          ami = ((create_node[:image]||{})[:external_ref]||{})[:image_id]
          raise ErrorCannotCreateNode.new unless ami
          create_options = {:image_id => ami}
          #TODO: right now hardcoding size and groups
          create_options.merge!(:flavor_id => "t1.micro",:groups => ["basic"])
          response = @@conn.server_create(create_options)
          instance_id = response[:id]
          state = response[:state]
          external_ref = {
            :instance_id => instance_id,
            :type => "ec2_instance"
          }
          Log.info("node created with instance id #{instance_id}; waiting for it to be available")
          pp [:node_created,response]
          create_node[:node].merge!(:external_ref => external_ref)
          create_node.save_new_node_info()
        else
          Log.info("node already created with instance id #{instance_id}; waiting for it to be available")
        end
        CommandAndControl.wait_for_node_to_be_ready(create_node[:node])
        updated_server_state = @@conn.server_get(instance_id)
        pp [:updated_server_state,updated_server_state]
        Log.info("node #{instance_id} is available")

        {:status => "succeeded",
          :node => {
            :external_ref => {
              :instance_id => instance_id,
              :type => "ec2_instance"
            }
          }
        }
      end
     private
      #TODO: sharing ec2 connection with ec2 datasource
      @@conn ||= CloudConnect::EC2.new
    end
  end
end
