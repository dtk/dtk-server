module DTKModule
  module Aws::Stdlib
    class CredentialHandler 
      require_relative('credential_handler/iam_instance_profile')
      # require_relative('credential_handler/keys') for giving explicit keys
      require_relative('credential_handler/secret_server') 
      
      # Returns a ::Aws::Credentials object or nil if credentials not needed
      def self.aws_credentials(credentials_handle)
        # default is iam_instance_profile
        if credentials_handle.nil? or credentials_handle[:iam_instance_profile]
          IamInstanceProfile.new((credentials_handle || {})[:iam_instance_profile]).aws_credentials
        elsif secret_server_hash = credentials_handle[:secret_server]
          SecretServer.new(secret_server_hash).aws_credentials
        else
          fail "Cannot find an AwsConn processor in the credentials_hash"
        end
      end

    end
  end
end
