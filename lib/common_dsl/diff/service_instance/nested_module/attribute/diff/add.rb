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
module DTK; module CommonDSL 
    class Diff::ServiceInstance::NestedModule
      class Attribute::Diff
        class Add 
            include Mixin
            
            def self.process(component, attribute_name, attribute_value, extra_fields = {})
              name = attribute_name.to_s
              attr_to_insert = { 
                ref: name,
                display_name: name,
                value_asserted: attribute_value,
                component_component_id: component.id
              }.merge(extra_fields)
              attributes = [attr_to_insert]
              attr_mh = component.id_handle.createMH(model_name: :attribute, parent_model_name: :component)
              new_attr_idh = Model.create_from_rows(attr_mh, attributes, convert: true).first
            end

        end
      end
    end
end; end
