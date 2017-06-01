require 'json'
module DTKModule
  class Aws::Stdlib::CredentialHandler 
    class SecretServer < self
      require_relative('secret_server/grpc_helper')
      include DTK::Attributes::Mixin
      def initialize(hash_params)
        @grpc_helper = GrpcHelper.new(*values(hash_params, :host, :port))
        @name = values(hash_params, :name) # TODO: :name not in there now
        fail "Needs to be refined after refactor"
      end
      
      def add_to_secret_server(aws_access_key_id, aws_secret_access_key)
        @grpc_helper.add_to_secret_server(@name, aws_access_key_id, aws_secret_access_key)
      end
      
      # Returns a ::Aws::Credentials object
      def aws_credentials
        # TODO: use @name
        aws_credentials_string = @grpc_helper.get_aws_credentials_json_string
        cred_hash = JSON.parse(aws_credentials_string)
        ::Aws::Credentials.new(cred_hash['aws_access_key_id'], cred_hash['aws_secret_access_key'])
      end
    end
  end
end
