module DTKModule
  module Aws::Stdlib
    class AwsCredentialHandle < ::Hash
      require_relative('aws_credential_handle/iam_instance_profile')
      # require_relative('aws_credential_handle/keys') for giving explicit keys

      def initialize(credentials_handle_hash = {})
        super()
        replace(credentials_handle_hash)
      end

      # In methods below credentials_handle can be nil, a ::Hash or AwsCredentialHandle object
      def self.aws_credentials_and_region_hash(credentials_handle)
        { region: region(credentials_handle) }.merge(aws_credentials(credentials_handle)) 
      end

      DEFAULT_REGION = 'us-east-1'

      def region
        self[:region] || DEFAULT_REGION
      end

      private

      def self.region(credentials_handle)
        if credentials_handle.respond_to?(:region)
          credentials_handle.region
        else
          (credentials_handle || {})[:region] || DEFAULT_REGION 
        end
      end

      def self.aws_credentials(credentials_handle)
        # default is iam_instance_profile
        if (credentials_handle || {}).empty? or credentials_handle[:iam_instance_profile]
          IamInstanceProfile.new((credentials_handle || {})[:iam_instance_profile]).aws_credentials
        else
          fail "Cannot find a vaild credentials handle"
        end
      end

    end
  end
end
