module XYZ
module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      def execute_implemntation(create_node_state_change)
        #TODO: rather than retuirning nill wil raise errors
        ami = (((create_node_state_change||{})[:image]||{})[:external_ref]||{})[:image_id]
        return nil unless ami
        create_options = {:image_id => ami}
        #TODO: right now hardcoding size and groups
        create_options.merge!(:flavor_id => "t1.micro",:groups => ["basic"])
        response = @@conn.server_create(create_options)
        pp [:response,response]
        instance_id = response[:id]
        state = response[:state]
        external_ref = {
          :instance_id => instance_id, 
          :type => "ec2_instance"
        }
        create_node_state_change[:node].merge(:external_ref => external_ref)
      end
     private
      #TODO: sharing ec2 connection with ec2 datasource
      @@conn ||= CloudConnect::EC2.new
    end
  end
end
