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
  class NodeComponent
    class IAAS::Ec2::Type::Group
      class Instance
        MAPPING = {
          instance_id: 'instance_id',
          host_addresses_ipv4: 'host_addresses_ipv4'
        }
        def initialize(instance_hash)
          @instance_hash = instance_hash
        end

        def self.value(instance_hash, key)
          new(instance_hash).value(key)
        end

        def value(key)
          index = (MAPPING[key] || fail("Illegal key '#{key}'"))
          self.instance_hash[index]
        end

        protected

        attr_reader :instance_hash
      end
    end
  end
end      
