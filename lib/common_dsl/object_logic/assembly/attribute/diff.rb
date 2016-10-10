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
  class ObjectLogic::Assembly::Attribute
    class Diff < CommonDSL::Diff::Base
      class Modify < CommonDSL::Diff::Element::Modify
        def process(_result, _opts = {})
          # result does not need to be updated since attribute changes dont entail service-side
          # modification to dsl
          self.class.update_and_propagate_attribute(existing_object, new_val)
          update_and_propagate_attribute_when_node_property?
        end

        private

        def self.update_and_propagate_attribute(attribute, new_val)
          ::DTK::Attribute.update_and_propagate_attribute_from_diff(attribute, new_val)        
        end

        def update_and_propagate_attribute_when_node_property?
          node_name, attribute_name = @qualified_key.is_node_attribute?
          if attribute_name
            if node_component_attribute = ::DTK::Attribute::Pattern.node_component_attribute?(parent_node_when_node_attribute, attribute_name)
              self.class.update_and_propagate_attribute(node_component_attribute, new_val)
            end
          end
        end

        def parent_node_when_node_attribute
          @parent_node ||= existing_object.get_node
        end
      end
    end
  end
end; end
