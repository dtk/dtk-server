require File.expand_path('ec2', File.dirname(__FILE__))
module XYZ
  module CommandAndControlAdapter
    class Ec2__mock < Ec2
     private
      def self.wait_for_node_to_be_ready(node)
        sleep(5)
      end

      #TODO: look at fog's mock
      class MockEc2Connection
        def server_create(create_options)
          instance_id = generate_unique_instance_id(create_options)
          CommonFields.merge(:state => "pending", :id => instance_id,:created_at => created_at(instance_id),:block_device_mapping=>[])
        end
        

        def server_get(instance_id)
          #TODO stub
          network_attrs = {
            :ip_address=>"184.73.10.255",
            :private_dns_name=>"domU-12-31-39-02-D8-05.compute-1.internal",
            :private_ip_address=>"10.248.223.243",
            :dns_name=>"ec2-184-73-10-255.compute-1.amazonaws.com",
          }
          #TODO: stub
          block_device_mapping =
            [{"volumeId"=>"vol-34820c5c",
               "deviceName"=>"/dev/sda1",
               "deleteOnTermination"=>true,
               "attachTime"=>"Tue Jan 25 18:57:08 UTC 2011",
               "status"=>"attached"}]

          CommonFields.merge(network_attrs).merge(:state => "running", :id => instance_id,:created_at => created_at(instance_id), :block_device_mapping => block_device_mapping)
        end

      private
      def created_at(instance_id)
        #TODO: stub
        "Tue Jan 25 18:57:04 UTC 2011"
      end

      def generate_unique_instance_id(create_options)
        #TODO: stub
        "i-3706b75b"
      end
      #TODO: may put this in Config file
      CacheFile = "#{R8::Config[:sys_root_path]}/cache/ec2_mock.json"
      @@cache_contents = nil

      CommonFields = {
        :image_id=>"ami-ee38c987",
        :flavor_id=>"t1.micro",
        :private_dns_name=>nil,
        :state=>"pending",
        :monitoring=>[{"state"=>false}],
        :availability_zone=>"us-east-1a",
        :groups=>["basic"],
        :ami_launch_index=>0,
        :kernel_id=>"aki-3af50453",
        :product_codes=>[],
        :reason=>nil,
        :client_token=>nil,
        :root_device_type=>"ebs"
      }
    end

      def self.conn()
        Conn[0] ||= MockEc2Connection.new
      end
      Conn = Array.new
    end
  end
end
