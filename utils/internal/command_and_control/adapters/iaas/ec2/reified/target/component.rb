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
  class CommandAndControlAdapter::Ec2::Reified::Target
    class Component < DTK::Service::Reified::Component
      r8_nested_require('component', 'type')

      def validate_an_converge!
        Log.error("Absract method that should be overwritten for class '#{self.class}'")
        []
      end

      class Vpc < self
        DefaultRegion = 'us-east-1'
        AttributeNames = ['reqion', 'aws_access_key_id', 'aws_secret_access_key']
        def initialize(vpc_service_component)
          @vpc_service_component = vpc_service_component
          @reqion, @aws_access_key_id, @aws_secret_access_key = get_attribute_values(AttributeNames, vpc_service_component)
          @region ||= DefaultRegion
        end 

        def credentials_with_region 
          { 
            aws_access_key_id: @aws_access_key_id,
            aws_secret_access_key: @aws_secret_access_key,
            region: @region
          }
        end
      end

      class VpcSubnet < self
        def initialize(vpc_subnet_service_component)
          @vpc_subnet_service_component = vpc_subnet_service_component
        end
      end

      class SecurityGroup < self
        attr_reader :group_name

        AttributeNames = ['name']
        def initialize(sg_service_component)
          @sg_service_component = sg_service_component
          @group_name = get_attribute_values(AttributeNames, sg_service_component)
        end 
      end
    end
  end
end

