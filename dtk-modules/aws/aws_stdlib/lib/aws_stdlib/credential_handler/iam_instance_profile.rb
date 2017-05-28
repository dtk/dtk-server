require 'json'
module DTKModule
  class Aws::Stdlib::CredentialHandler 
    class IamInstanceProfile < self
      def initialize(iam_instance_profile)
        #iam_instance_profile can be nil
      end
      # Returns a ::Aws::Credentials or nil if no credentials object needed
      def aws_credentials
        nil
      end
    end
  end
end
