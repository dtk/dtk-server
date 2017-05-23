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
      class AbstractNode < self
        def self.process_abstract_node_components!(parsed_assembly)
          if parsed_components = parsed_assembly.val(:Components)
            
            abstract_nodes_to_add = parsed_components.inject([]) do |a, (component_name, parsed_component)|
              (node_info = abstract_node_info?(component_name, parsed_component)) ? a + [node_info] : a
            end

            abstract_nodes_to_add.each do |node_info|
              parsed_node = create_entry_under_node_section!(parsed_assembly, node_info)

              move_nested_and_node_group_attributes_to_node!(parsed_node, node_info)

              # create (iaas specfic) node component
              create_node_component!(parsed_assembly, node_info)
              
              # remove abstract node component
              parsed_components.delete(node_info.component_name)
            end
          end
        end
        
        private
        
        def self.create_entry_under_node_section!(parsed_assembly, node_info)
          parsed_node = find_or_add_node_under_node_section!(parsed_assembly, node_info.name)
        end

        def self.move_nested_and_node_group_attributes_to_node!(parsed_node, node_info)
          if node_info.type == Type::GROUP
            NodeAttribute.move_component_node_group_attributes_under_node!(parsed_node, node_info.parsed_component)
          end
          # move nested components to node
          if nested_components = node_info.parsed_component.delete_key(:Components)
            parsed_node.set(:Components, nested_components)
          end
        end

        def self.create_node_component!(parsed_assembly, node_info)
          # at this point node_info.parsed_component wil not have components and just attributes that should be under node componenr rather than node section
          find_or_add_node_component!(parsed_assembly, iaas_type, node_info.name, node_info.type, node_content: node_info.parsed_component) 
        end

        ### == lower level methods
        def self.find_or_add_node_under_node_section!(parsed_assembly, node_name)
          unless parsed_nodes = parsed_assembly.val(:Nodes) 
            parsed_nodes =  canonical_hash
            parsed_assembly.set(:Nodes, parsed_nodes)
          end

          Log.error("Unexpected that the key '#{node_name}' is in: #{parsed_nodes.inspect}") if parsed_nodes.has_key?(node_name)
          parsed_nodes[node_name] ||= canonical_hash
        end
        
        def self.move_nested_components_under_node!(parsed_node, node_info)
          parsed_component = node_info.parsed_component
          if nested_components = parsed_component.val(:Components) 
            Log.error("Unexpected that the key :Components is set in: #{parsed_node.inspect}") unless parsed_node.val(:Components).nil?
            parsed_node.set(:Components, nested_components)
          end
        end

        PARSING_MAP = {
          Type::SINGLE =>  {
            regexp: /^node\[([^\]]+)\]$/,
            component_type: 'node'
          },
          Type::GROUP  => {
            regexp: /^node_group\[([^\]]+)\]$/,
            component_type: 'node_group'
          }
        }
        COMPONENT_TYPES = PARSING_MAP.values.map { |info| info[:component_type] }

        NodeInfo = Struct.new(:component_name, :name, :type, :parsed_component)
        # returns Info if this component is an abstract node; otherwise nil
        def self.abstract_node_info?(component_name, parsed_component)
          PARSING_MAP.each do |node_type, info|
            if component_name =~ info[:regexp]
              node_name = $1
              return NodeInfo.new(component_name, node_name, node_type, parsed_component)
            end
          end
          nil
        end
        
      end
    end
  end
end
