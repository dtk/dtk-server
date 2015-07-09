require File.expand_path('ec2', File.dirname(__FILE__))
require 'ipaddr'
module XYZ
  module CommandAndControlAdapter
    class Ec2__mock < Ec2
      def self.default_user_data
      end
      def self.get_node_operational_status(_node)
      end

      private

      def self.wait_for_node_to_be_ready(_node)
        sleep(5)
      end

      # TODO: look at fog's mock
      class MockEc2Connection
        def server_create(create_options)
          instance_id = generate_unique_instance_id(create_options)
          instance_attr = {state: 'pending', id: instance_id,created_at: created_at(instance_id),block_device_mapping: []}
          CommonCreateFields.merge(create_options).merge(instance_attr)
        end


        def server_get(instance_id)
          # TODO: stub
          # hard coding AWS east addresses
          addr = generate_random_ipv4('184.73.0.1','184.73.255.254')
          network_attrs = {
            ip_address: addr,
            private_dns_name: 'domU-12-31-39-02-D8-05.compute-1.internal',
            private_ip_address: '10.248.223.243',
            dns_name: "ec2-#{addr.gsub('.','-')}.compute-1.amazonaws.com"
          }
          # TODO: stub
          block_device_mapping =
            [{'volumeId'=>'vol-34820c5c',
               'deviceName'=>'/dev/sda1',
               'deleteOnTermination'=>true,
               'attachTime'=>'Tue Jan 25 18:57:08 UTC 2011',
               'status'=>'attached'}]

          instance_attr = {state: 'running', id: instance_id,created_at: created_at(instance_id), block_device_mapping: block_device_mapping}
          stored_info = get_cache_info(instance_id)
          CommonCreateFields.merge(network_attrs).merge(instance_attr).merge(stored_info)
        end

        private

      def created_at(_instance_id)
        # TODO: stub
        'Tue Jan 25 18:57:04 UTC 2011'
      end

      def generate_unique_instance_id(create_options)
        id = nil
        loop do
          id = generate_random_id()
          next if id_in_cache(id)
          add_instance_to_cache_and_save(id,create_options)
          break
        end
        id
      end

      def add_instance_to_cache_and_save(id,create_options)
        cache[id] = create_options
        save_cache()
      end

      def get_cache_info(instance_id)
        cache[instance_id]||{}
      end

      def generate_random_id
        'i-'+(1..8).map{|_x|rand(15).to_s(16)}.join('')
      end

      def generate_random_ipv4(lower_ip_dot_n,upper_ip_dot_n)
        lower = IPAddr.new(lower_ip_dot_n)
        upper = IPAddr.new(upper_ip_dot_n)
        offset = rand(1+upper.to_i - lower.to_i)
        IPAddr.new(lower.to_i + offset,Socket::AF_INET).to_s
      end

      ####
      def id_in_cache(id)
        cache.key?(id)
      end

      def cache
        @@cache_contents ||= File.exists?(CacheFile) ? JSON.parse(IO.read(CacheFile)) : {}
      end

      def save_cache
        file_contents = JSON.pretty_generate(@@cache_contents)
        File.open(CacheFile, 'w') {|fhandle|fhandle.write(file_contents)}
      end
      # TODO: may put this in Config file
      CacheFile = "#{R8::Config[:sys_root_path]}/cache/application/ec2_mock.json"
      @@cache_contents = nil

      CommonCreateFields = {
        flavor_id: 'm1.small',
        private_dns_name: nil,
        monitoring: [{'state'=>false}],
        availability_zone: 'us-east-1a',
        groups: ['default'],
        ami_launch_index: 0,
        kernel_id: 'aki-3af50453',
        product_codes: [],
        reason: nil,
        client_token: nil,
        root_device_type: 'ebs'
      }
    end

      def self.conn
        Conn[0] ||= MockEc2Connection.new
      end
      Conn = []
    end
  end
end
