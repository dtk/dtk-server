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
  class Ec2
    class TargetService
      class Component
        MAPPINGS_NAME = {
          :provider       => 'aws::iam_user',
          :vpc            => 'aws::vpc',
          :vpc_subnet     => 'aws::vpc_subnet',
          :security_group => 'aws::security_group'
        }
        MAPPINGS_TYPE = MAPPINGS_NAME.inject({}) { |h, (type, cmp_name)| h.merge(type => cmp_name.gsub('::', '__')) }
        METHODS = MAPPINGS_NAME.keys

        class Name < self
          class << self
            def method_missing(method)
              MAPPINGS_NAME[method] || super
            end
          end
        end

        class Type < self
          class << self
            def method_missing(method)
              MAPPINGS_TYPE[method] || super
            end
          end
        end

        class << self
          def respond_to?(method)
            METHODS.include?(method)
          end
        end
      end
    end
  end
end; end
