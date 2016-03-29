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
  class CommandAndControlAdapter::Ec2::Reified::Target::Component
    class Type 
      Mapping = {
        # TODO: not sure if need to check provider since its attributes are pushed to VPC
        # :provider       => 'aws::iam_user',
        :vpc            => 'aws::vpc',
        :vpc_subnet     => 'aws::vpc_subnet',
        :security_group => 'aws::security_group'
      }
      Names = Mapping.values
      All = Mapping.keys

      class << self
        def name(cmp_type)
          Mapping[cmp_type]
        end

        def method_missing(method, *args, &body)
          Mapping[method] || super
        end
      end
      
      def respond_to?(method)
        All.include?(method)
      end
    end
  end
end


