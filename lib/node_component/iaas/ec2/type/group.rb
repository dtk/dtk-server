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
    class IAAS::Ec2::Type
      class Group < self
        require_relative('group/instance')

        def generate_new_client_token?
          # generate if does not exists or there are new group members to create
          attribute_value?(:client_token).nil? or new_group_members_to_create?
        end
        
        HOST_ADDRESSES_IPV4 = 'host_addresses_ipv4'
        def dynamic_attributes_special_processing
          instance_attributes_array.each do |instance_attributes|
            if host_addresses_ipv4_attr = instance_attributes.attribute?(HOST_ADDRESSES_IPV4)
              host_addresses_ipv4_val = instance_attributes.value?(HOST_ADDRESSES_IPV4)
              attribute_row = { id: host_addresses_ipv4_attr.id, value_derived: host_addresses_ipv4_val }
              Attribute.update_and_propagate_attributes(attribute_mh, [attribute_row], dynamic_attributes: true)
            else
              Log.error("Unexpected that 'instance_attributes.attribute?(HOST_ADDRESSES_IPV4' is nil")
            end
          end
        end

        private
        
        def new_group_members_to_create?
          existing_instances = (attribute_value?(:instances) || []).reject { |instance| Instance.value(instance, :instance_id).nil? }
          existing_instances.size < cardinaility
        end
    
        def cardinaility
          string_value = attribute_value(:cardinality)
          string_value.to_i
        end
        
      end
    end
  end
end

