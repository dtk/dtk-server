module DTKModule
  class Aws::Stdlib::AwsCredentialHandle 
    class IamInstanceProfile < self
      def initialize(_iam_instance_profile)
        super()
        # TODO: handle a non nil iam_instance_profile argument
      end
      # Returns a ::Aws::Credentials or nil if no credentials object needed
      def aws_credentials
        {}
      end
    end
  end
end
