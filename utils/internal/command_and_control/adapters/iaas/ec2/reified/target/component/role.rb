#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'rest_client'
module DTK; module CommandAndControlAdapter
  class Ec2; class Reified::Target
    class Component
      class Role < self
        Attributes = [:name, :aws_access_key_id, :aws_secret_access_key]
        def initialize(reified_target, vpc_service_component)
          super(reified_target, vpc_service_component)
        end 

        # Returns an array of violations; if no violations [] is returned
        def validate_and_fill_in_values!
          ret = [] # meanng no errors
          if any_asserted_credential?
            if error_array = asserted_credentials_errors?
              ret = error_array
            end
          else !credentials_through_aws_role_meta_info?
            ret = [Violation::InvalidIAMRole.new(role_name)]
          end
          ret
        end
        
        def credentials?
          asserted_credentials? || credentials_through_aws_role_meta_info?
        end
        
        def credentials(opts = {})
          credentials? || fail(Error, "Unexpected that credentials are nil")
        end
        
        private
        
        def role_name
          name
        end

        def type
          :role
        end

        def any_asserted_credential?
          !aws_access_key_id.nil? or !aws_secret_access_key.nil?
        end
        
        def asserted_credentials?
          aws_access_key_id     = aws_access_key_id()
          aws_secret_access_key = aws_secret_access_key()
          credentials_hash(aws_access_key_id, aws_secret_access_key) if aws_access_key_id and aws_secret_access_key
        end
        
        def credentials_hash(aws_access_key_id, aws_secret_access_key)
          {
            aws_access_key_id: aws_access_key_id,
            aws_secret_access_key: aws_secret_access_key
          }
        end

        # returns nil or an array of errors
        def asserted_credentials_errors?
          aws_access_key_id     = aws_access_key_id()
          aws_secret_access_key = aws_secret_access_key()
          if aws_access_key_id and aws_secret_access_key.nil?
            [Violation::MissingCredential.new(type, name, :aws_secret_access_key)]
          elsif aws_access_key_id.nil? and aws_secret_access_key
            [Violation::MissingCredential.new(type, name, :aws_access_key_id)]
          elsif aws_access_key_id and aws_secret_access_key
            unless Ec2.credentials_ok?(credentials_hash(aws_access_key_id, aws_secret_access_key).merge(region: Ec2::DefaultRegion))
              [Violation::InvalidCredentials.new(self, :aws_access_key_id, :aws_secret_access_key)]
            end
          end
        end

        METADATA_URL = 'http://169.254.169.254/latest/meta-data'
        ENDPOINT_ROOT = 'iam/security-credentials'
        def credentials_through_aws_role_meta_info?
          ret = nil
          begin
            # String.new needed because of the issue in rest-client: no _dump_data is defined for class OpenSSL::X509::Store
            response = String.new(RestClient.get("#{METADATA_URL}/#{ENDPOINT_ROOT}/#{role_name}"))
            role_details = JSON.parse(response)
            if role_details['Code'] == 'Success'
              ret = credentials_hash(role_details['AccessKeyId'], role_details['SecretAccessKey'])
            end
          rescue RestClient::ResourceNotFound
            # This is legitimate response if role not found
            ret = nil
          end
          ret
        end


      end
    end
  end; end
end; end



