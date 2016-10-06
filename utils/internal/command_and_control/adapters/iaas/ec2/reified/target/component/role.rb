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

module DTK; module CommandAndControlAdapter
  class Ec2; class Reified::Target
    class Component
      class Role < self
        Attributes = [:aws_access_key_id, :aws_secret_access_key]
        def initialize(reified_target, vpc_service_component)
          super(reified_target, vpc_service_component)
        end 

        # Returns an array of violations; if no violations [] is returned
        def validate_and_fill_in_values!
          ret = [] # meaning no errors
          if !credentials?
            ret
          elsif Ec2.credentials_ok?(credentials_with_default_region)
            ret
          else
            [Violation::InvalidCredentials.new(self, :aws_access_key_id, :aws_secret_access_key)]
          end
        end

        def credentials?
          aws_access_key_id     = aws_access_key_id()
          aws_secret_access_key = aws_secret_access_key()
          if aws_access_key_id and aws_secret_access_key
            credentials(aws_access_key_id: aws_access_key_id, aws_secret_access_key: aws_secret_access_key) 
          end
        end

        def credentials(opts = {})
          {
            aws_access_key_id: opts[:aws_access_key_id] || aws_access_key_id,
            aws_secret_access_key: opts[:aws_secret_access_key] || aws_secret_access_key
          }
        end

        private

        def credentials_with_default_region
          credentials.merge(region: Ec2::DefaultRegion) 
        end

      end
    end
  end; end
end; end


