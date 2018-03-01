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

        # dyn_attr_val_info is any array with each element having form {:id =>.., :attribute_value => ..}
        def self.create_from_dyn_attr_val_info(dyn_attr_val_info, attribute_mh)
          ret = []
          sp_hash = {
            cols: [:id, :group_id, :display_name],
            filter: [:and, [:oneof, :id, dyn_attr_val_info.map { |info| info[:id] }], [:eq, :display_name, 'instances']]
          }
          unless instances_attr = Model.get_obj(attribute_mh, sp_hash)
            Log.error("Unexpected that cant find the instances attribute")
            return ret
          end

          unless instances_entry = dyn_attr_val_info.find { |info| info[:id] == instances_attr.id }
            Log.error("Unexpected that cant find the instances attribute")
            return ret
          end
          unless instance_hash_array = instances_entry[:attribute_value]
            Log.error("Unexpected that instances_entry[:attribute_value] is nil")
            return ret
          end
          instance_hash_array.map { |instance_hash| new(instance_hash) }
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
