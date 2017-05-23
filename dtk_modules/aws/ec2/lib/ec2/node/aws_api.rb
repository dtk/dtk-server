module DTKModule
  class Ec2::Node
    module AwsApi
      require_relative('aws_api/operation')
      require_relative('aws_api/map_from_aws_attributes')
      require_relative('aws_api/instance_info')

      def self.operation_class(type)
        Operation.const_get(type.capitalize).new(client: client)
      end

    end
  end
end
