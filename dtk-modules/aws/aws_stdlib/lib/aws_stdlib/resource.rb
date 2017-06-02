module DTKModule
  module Aws::Stdlib
    class Resource
      require_relative('resource/operation')
      require_relative('resource/output_settings')

      attr_reader :attributes, :client

      def initialize(credentials_handle, name, attributes)
        @name              = name
        @attributes        = attributes
        @client            = aws_client_class.new(client_opts(credentials_handle))
      end

      private

      def aws_api_operation(operation_type)
        aws_api_operation_class(operation_type).new(self)
      end
      
      def aws_api_operation_class(operation_type)
        self.class::Operation.aws_api_operation_class(operation_type)
      end

      def aws_client_class
        fail "This method should be overwritten by concrete class"
      end

      # credentials_handle can be nil, a ::Hash or AwsCredentialHandle object
      def client_opts(credentials_handle)
        AwsCredentialHandle.aws_credentials_and_region(credentials_handle)
      end

    end
  end
end


