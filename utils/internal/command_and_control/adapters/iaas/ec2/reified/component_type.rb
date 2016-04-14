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
  module CommandAndControlAdapter::Ec2::Reified
    class ComponentType 
      class << self
        def all
          mapping.keys
        end

        def name(cmp_type)
          mapping[cmp_type]
        end

        def names
          mapping.values
        end

        def method_missing(method, *args, &body)
          mapping[method] || super
        end
      
        def respond_to?(method)
          all.include?(method)
        end

        private
        
        def mapping
          self::Mapping
        end
      end
    end
  end
end


