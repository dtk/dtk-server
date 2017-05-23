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
    class Parsing::CommonModule
      class NodeSection  < self
        def self.process_nodes_in_node_section!(parsed_assembly)
          (parsed_assembly.val(:Nodes) || {}).each_value do |parsed_node| 
            node_component = find_or_add_node_component!(parsed_assembly, iaas_type, parsed_node.name, node_type(parsed_node))
            NodeAttribute.move_attributes_to_node_component!(node_component, parsed_node)
          end
        end

        private

        NODE_TYPE_KEY   = 'type'
        NODE_GROUP_TYPE = 'group'
        def self.node_type(parsed_node)
          ret = Type::SINGLE
          if attributes = parsed_node.val(:Attributes)
            if type_attribute = attributes[NODE_TYPE_KEY]
              ret = Type::GROUP if type_attribute.val(:Value) == NODE_GROUP_TYPE 
            end
          end
          ret
        end

        def self.matching_component?(parsed_components, component_name)
          if match_in_array_form = (parsed_components && parsed_components.find { |name, parsed_component| name == component_name })
            canonical_hash.merge(component_name => match_in_array_form[1])
          end
        end

      end
    end
  end
end
