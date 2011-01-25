require File.expand_path('ec2', File.dirname(__FILE__))
module XYZ
  module CommandAndControlAdapter
    class Ec2__mock < Ec2
     private
      #TODO: may put this in Config file
      CacheFile = "#{R8::Config[:sys_root_path]}/cache/ec2_mock.json"
      @@cache_contents = nil

      def self.wait_for_node_to_be_ready(node)
        sleep(5)
      end

      #TODO: look at fog's mock
      class MockEc2Connection
        def server_create(create_options)
          ret = {
            :block_device_mapping=>[],
            :image_id=>"ami-ee38c987",
            :flavor_id=>"t1.micro",
            :private_dns_name=>nil,
            :created_at=>Tue Jan 25 18:57:04 UTC 2011,
            :state=>"pending",
            :monitoring=>[{"state"=>false}],
            :availability_zone=>"us-east-1a",
            :groups=>["basic"],
            :ami_launch_index=>0,
            :kernel_id=>"aki-3af50453",
            :product_codes=>[],
            :dns_name=>nil,
            :reason=>nil,
            :id=>"i-3706b75b",
            :client_token=>nil,
            :root_device_type=>"ebs"}

        end
        def server_get(instance_id)
          ret = {
            :image_id=>"ami-ee38c987",
            :block_device_mapping=>
            [{"volumeId"=>"vol-34820c5c",
               "deviceName"=>"/dev/sda1",
               "deleteOnTermination"=>true,
               "attachTime"=>Tue Jan 25 18:57:08 UTC 2011,
               "status"=>"attached"}],
            :flavor_id=>"t1.micro",
            :ip_address=>"184.73.10.255",
            :private_dns_name=>"domU-12-31-39-02-D8-05.compute-1.internal",
            :created_at=>Tue Jan 25 18:57:04 UTC 2011,
            :state=>"running",
            :private_ip_address=>"10.248.223.243",
            :tags=>{},
            :monitoring=>[{"state"=>false}],
            :availability_zone=>"us-east-1a",
            :state_reason=>{},
            :groups=>["basic"],
            :ami_launch_index=>0,
            :kernel_id=>"aki-3af50453",
            :product_codes=>[],
            :dns_name=>"ec2-184-73-10-255.compute-1.amazonaws.com",
            :reason=>nil,
            :id=>"i-3706b75b",
            :client_token=>nil,
            :root_device_type=>"ebs"}

        end
      end

      def self.conn()
        Conn[0] ||= MockEc2Connection.new
      end
      Conn = Array.new
    end
  end
end
