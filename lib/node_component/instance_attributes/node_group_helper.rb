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
    class InstanceAttributes
      class NodeGroupHelper
        def initialize(node_group_component)
          @instances_attribute  = node_group_component.attribute(:instances) || fail(Error, "Unexpected that 'instances' attribute does not exist")
        end
        
        def attribute_name_value_hash(index)
          (instance = instance?(index)) ? instance : {}
        end
        
        private
        
        attr_reader :instances_attribute
        
        def instance?(index)
          instance_value? && instance_value?[index]
        end
        
        def instance_value?
          if @instance_value_set
            @instance_value
          else
            @instance_value_set = true
            @instance_value = instances_attribute[:attribute_value]
          end
        end
        
      end
    end
  end
end
