module DTKModule
  module Ec2::Node::AwsApi
    module MapFromAwsAttributes
      MAPPING = 
        [
         { :block_device_mappings => :map_block_device_mappings },
         { :instance_state => :map_instance_state },
         { :host_addresses_ipv4 => :map_host_addresses_ipv4 },
         :instance_id, 
         :private_ip_address, 
         :public_ip_address, 
         :private_dns_name, 
         :public_dns_name
        ]
      NDX_MAPPING = MAPPING.inject({}) { |h, el| el.kind_of?(::Symbol) ? h.merge(el => nil) : h.merge(el) }

      def self.value(key, aws_instance)
        if method = NDX_MAPPING[key]
          send(method, aws_instance)
        else
          aws_instance.send(key)
        end
      end

      private

      attr_reader :client

      def self.map_instance_state(aws_instance)
        aws_instance.state.name
      end

      def self.map_host_addresses_ipv4(aws_instance)
        [aws_instance.public_dns_name]
      end

      EBS_KEYS = [:volume_id, :status, :attach_time, :delete_on_termination]
      def self.map_block_device_mappings(aws_instance)
        block_device_mappings = aws_instance.block_device_mappings.map do |el|
          ebs = el.ebs
          EBS_KEYS.inject(device_name: el.device_name) do |h, ebs_key|
            h.merge(ebs_key => ebs.send(ebs_key))
          end
        end
      end
    end
  end
end
