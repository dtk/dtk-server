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
  class ConfigAgent::Adapter::Dynamic
    module AttributeRequestForm
      module SystemAttribute
        
        SYSTEM_ATTRIBUTES = {
          service_instance_name: {
            value_lambda: lambda { |assembly_instance| assembly_instance.display_name }, 
            datatype: 'string', 
            hidden: false
          },
          server_id: {
            value_lambda: lambda { |_assembly_instance| R8::Config[:server_id] },
            datatype: 'string', 
            hidden: false
          },
          server_alias: {
            # R8::Config[:server_alias] could be nil
            value_lambda: lambda { |_assembly_instance| R8::Config[:server_alias] },
            datatype: 'string', 
            hidden: false
          }
        }

        def self.system_attributes(assembly_instance)
          SYSTEM_ATTRIBUTES.inject({}) do |h, (attribute_name, input)|
            qualified_attribute_name = AttributeType.system_attribute_name(attribute_name)
            h.merge(qualified_attribute_name => Info.new(input[:value_lambda].call(assembly_instance), input[:datatype], input[:hidden]))
          end
        end
        
      end
    end
  end        
end
