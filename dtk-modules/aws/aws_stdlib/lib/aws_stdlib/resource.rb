module DTKModule
  module Aws::Stdlib
    class Resource
      require_relative('resource/operation')
      require_relative('resource/output_settings')

      attr_reader :attributes, :client

      def initialize(credentials_handle, name, attributes)
        aws_credentials_and_region_hash = AwsCredentialHandle.aws_credentials_and_region_hash(credentials_handle)
        @name               = name
        @attributes         = attributes
        @region             = aws_credentials_and_region_hash[:region]
        @client             = aws_client_class.new(aws_credentials_and_region_hash)
      end

      private

      attr_reader :region 

      def aws_api_operation(operation_type)
        aws_api_operation_class(operation_type).new(self)
      end
      
      def aws_api_operation_class(operation_type)
        self.class::Operation.aws_api_operation_class(operation_type)
      end

      def aws_client_class
        fail "This method should be overwritten by concrete class"
      end

    end
  end
end


