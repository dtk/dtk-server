# Needed because of way grpc stubs refer to each other
GRPC_DEFS_DIR = 'grpc_helper'
qualified_grpc_defs_dir = File.join(File.expand_path(File.dirname(__FILE__)), GRPC_DEFS_DIR)
$LOAD_PATH.unshift(qualified_grpc_defs_dir) unless $LOAD_PATH.include?(qualified_grpc_defs_dir)

require_relative "#{GRPC_DEFS_DIR}/secret_server_services_pb"
module DTKModule
  class Aws::Stdlib::CredentialHandler::SecretServer 
    class GrpcHelper
      def initialize(secret_server_host, secret_server_port)
        @secret_server_host = secret_server_host
        @secret_server_port = secret_server_port
        @grpc_stub          = create_client_stub(secret_server_host, secret_server_port)
      end

      def get_aws_credentials_json_string(name)
        # TODO: update so pass in name to GetValueRequest
        response = make_request(:get_value, GetValueRequest.new(key: 'aws_credentials'))
        response.string_value
      end

      def add_to_secret_server(name, aws_access_key_id, aws_secret_access_key)
        # TODO: update so pass in name to SetMasterCredentialsRequest
        credentials_hash = { 'aws_access_key_id' => aws_access_key_id, 'aws_secret_access_key' => aws_secret_access_key }
        make_request(:set_master_credentials, SetMasterCredentialsRequest.new(credentials: credentials_hash))
      end

      private
      
      def create_client_stub(host, port)
        grpc_module::Stub.new("#{host}:#{port}", :this_channel_is_insecure)
      end

      def grpc_module 
        ::GrpcSecretServer
      end

      def make_request(method, request_object)
        response = @grpc_stub.send(method, request_object)
        if response.status_code != 0
          fail "Error Making GRPC request to secret server (status_code: #{response.status_code}, error_msg: #{response.error_msg})"
        end
        response
      end
    end
  end
end

