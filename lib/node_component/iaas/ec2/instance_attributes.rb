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
  class NodeComponent::IAAS::Ec2
    class InstanceAttributes < NodeComponent::InstanceAttributes 
      private

      ATTRIBUTES = [:instance_id, :instance_state, :private_ip_address, :public_ip_address, :private_dns_name, :public_dns_name, :host_addresses_ipv4, :block_device_mappings]

      def iaas_normalize(attributes_name_value_hash)
        symbol_hash = attributes_name_value_hash.inject({}) { |h, (n, v)| h.merge(n.to_sym => v) }
        ATTRIBUTES.inject({}) do |h, name| 
          (value = symbol_hash[name]) ? h.merge(normalize(name) => value) : h 
        end
      end

      NORMALIZE_MAPPING = {
        # no ec2 attributes to normalize since using ec2 names as canonical names
      }
      def normalize(name)
        NORMALIZE_MAPPING[name] || name
      end      
    end
  end
end

