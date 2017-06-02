module DTKModule
  module Aws::Stdlib
    class Attributes < DTKModule::DTK::Attributes
      def aws_credentials_handle
        credentials_handle_hash = value?(:credentials_handle) || {} 
        # if both credentials_handle has regio and region exeplicitly give, use the explicitly gievn value
        if region = value?(:region)
          credentials_handle_hash.merge!(region: region)
        end
        AwsCredentialHandle.new(credentials_handle_hash)
      end
    end
  end
end
