module XYZ
module CommandAndControlAdapter
    class Ec2 <  CommandAndControlIAAS
      def create_node_implementation(create_node_action)
        #TODO: rather than retuirning nill wil raise errors
        ami = (((create_node_action||{})[:image]||{})[:external_ref]||{})[:image_id]
        return nil unless ami
        create_options = {:image_id => ami}
        #TODO: right now hardcoding size and groups
        create_options.merge!(:flavor_id => "t1.micro",:groups => ["basic"])
        response = @@conn.server_create(create_options)
        pp [:response,response, :node,create_node_action[:node]]
        instance_id = response[:id]
        state = response[:state]
        #TODO: check that state is not failure and then wait until responds to a discovery
        sleep 100
        external_ref = {"instance_id" => instance_id, "type" => "ec2_instance"}
        create_node_action[:node].merge(:external_ref => external_ref)
      end
     private
      #TODO: sharing ec2 connection with ec2 datasource
      @@conn ||= CloudConnect::EC2.new
    end
  end
end
