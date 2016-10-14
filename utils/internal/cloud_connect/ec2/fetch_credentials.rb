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
module DTK
  class CloudConnect::EC2
    module FetchCredentials

      RETRIES = 10
      RETRY_SLEEP = 0.5
      def self.fetch_credentials(region)
        ret = nil
        tries = RETRIES
        while ret.nil? and tries > 0
          tries -= 1
          ret = fetch_credentials_without_retry(region)
          if ret.nil? and tries > 0
            Log.info("Retrying fetch_credentials") 
            sleep RETRY_SLEEP
          end
        end
        ret
      end

      LOCK = Mutex.new

      INSTANCE_METADATA_HOST = "http://169.254.169.254"
      INSTANCE_METADATA_PATH = "/latest/meta-data/iam/security-credentials/"
      INSTANCE_METADATA_AZ = "/latest/meta-data/placement/availability-zone/"

      CONTAINER_CREDENTIALS_HOST = "http://169.254.170.2"
      # From https://github.com/fog/fog-aws/blob/ecfc0a2905ce2ce7eb0946a44d55f7e49e35311d/lib/fog/aws/credential_fetcher.rb
      # Written here to make more robust
      def self.fetch_credentials_without_retry(region)
        LOCK.synchronize do
          begin
            role_data = nil
            az_data = nil
            if ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]
              connection = Excon.new(CONTAINER_CREDENTIALS_HOST)
              credential_path = ENV["AWS_CONTAINER_CREDENTIALS_RELATIVE_URI"]
              role_data = connection.get(:path => credential_path, :expects => 200).body
              
              connection = Excon.new(INSTANCE_METADATA_HOST)
              az_data = connection.get(:path => INSTANCE_METADATA_AZ, :expects => 200).body
            else
              connection = Excon.new(INSTANCE_METADATA_HOST)
              role_name = connection.get(:path => INSTANCE_METADATA_PATH, :expects => 200).body
              role_data = connection.get(:path => INSTANCE_METADATA_PATH+role_name, :expects => 200).body
              az_data = connection.get(:path => INSTANCE_METADATA_AZ, :expects => 200).body
            end
            
            session = Fog::JSON.decode(role_data)
            
            {
              region: region,
              aws_access_key_id: session['AccessKeyId'],
              aws_secret_access_key: session['SecretAccessKey'],
              aws_session_token: session['Token'],
              aws_credentials_expire_at: Time.xmlschema(session['Expiration'])
            }
          rescue Excon::Error => e
            Log.error_pp(['get file credential error', e, e.backtrace[0..5]])
            nil
          end
        end
      end
      
    end
  end
end

