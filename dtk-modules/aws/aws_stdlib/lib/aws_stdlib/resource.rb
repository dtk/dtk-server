module DTKModule
  module Aws::Stdlib
    class Resource
      require_relative('resource/operation')
      require_relative('resource/output_settings')

      # TODO: this shoudl be moved to module aws/ec2
      #require_relative('resource/ec2')

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

      DEFAULT_REGION = 'us-east-1'

      def client_opts(credentials_handle)
        # credentials_handle can be nil
        ret = { region: (credentials_handle || {})[:region] || DEFAULT_REGION }
        if credentials = CredentialHandler.aws_credentials(credentials_handle)
          ret.merge!(credentials: credentials)
        end
        ret
      end

    end
  end
end


