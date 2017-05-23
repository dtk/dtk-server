module DTKModule
  module Ec2::Node::AwsApi
    class InstanceInfo
      require_relative('instance_info/op_state')
      include OpState::Mixin

      def initialize(aws_ec2_types_instance)
        # aws_ec2_types_instance is of type Aws::EC2::Types::Instance
        @aws_ec2_types_instance = aws_ec2_types_instance
      end

      def method_missing(name, *args, &block)
        aws_ec2_types_instance.send(name, *args, &block)
      end
      
      def respond_to?(name)
        aws_ec2_types_instance.respond_to?(name) || super
      end

      def has_public_dns_name?
        ! (aws_ec2_types_instance.public_dns_name || '').empty?
      end

      def has_private_ip_address?
        ! (aws_ec2_types_instance.private_ip_address || '').empty?
      end

      def fail_on_terminate_state
        if in_a_terminate_state?
          fail DTK::Error::Usage, "Ec2 instance '#{aws_ec2_types_instance.instance_id}' has been terminated" 
        end
      end

      private
      
      attr_reader :aws_ec2_types_instance 

    end
  end
end
