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
    module Parsing
      module CommonModule
        # For each node, it creates a node_component if needed using the relevant node attributes in parsed node
        def self.add_node_components!(parsed_assembly)
          return unless parsed_nodes = parsed_assembly.val(:Nodes)
          parsed_nodes.each_value { |parsed_node| add_node_component!(parsed_assembly, parsed_node) }
        end
        
        private

        def self.add_node_component!(parsed_assembly, parsed_node)
          # TODO: DTK-2967: node component is hard wired to iaas-specfic and to ec2 as iaas choice
          node_component = find_or_add_node_component!(parsed_assembly, :ec2, parsed_node) 
          move_attributes_to_node_component!(node_component, parsed_node)
        end

        def self.find_or_add_node_component!(parsed_assembly, iaas_type, parsed_node)
          ret = nil
          parsed_components  = parsed_assembly.val(:Components)
          node_component_ref = NodeComponent.node_component_ref(iaas_type, parsed_node.name,  node_type: node_type(parsed_node))
          if match = matching_component?(parsed_components, node_component_ref)
            ret = match
          else
            ret = canonical_hash.merge(node_component_ref => canonical_hash)
            unless parsed_components
              parsed_components = canonical_hash
              parsed_assembly.set(:Components, parsed_components)
            end
            parsed_components.merge!(ret)
          end
          ret
        end

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

        NODE_ATTRIBUTES = ['image', 'size']
        def self.move_attributes_to_node_component!(node_component, parsed_node)
          return unless parsed_attributes = parsed_node.val(:Attributes)

          attr_val_pairs = NODE_ATTRIBUTES.inject({}) do |h, name|
            (val = find_attribute_value?(parsed_attributes, name)) ? h.merge(name => val) : h
          end
          return if attr_val_pairs.empty?
          
          unless attributes = node_component.val(:Attributes)
            attributes = canonical_hash
            node_component.values.first.set(:Attributes, attributes)
          end
          attr_val_pairs.each_pair do |attr_name, attr_val|
            attributes.merge!(attr_name => canonical_hash(:Value => attr_val)) unless attr_val.nil?
          end

          # remove from parsed_node any moved attributes, but in no caes remove type
          remove_attributes = attr_val_pairs.keys - ['type']
          update_hash = parsed_attributes.inject(canonical_hash) do |h, (name, v)|
            remove_attributes.include?(name) ? h : h.merge(name => v)
          end           
          parsed_node.set(:Attributes, update_hash)
          nil
        end

        def self.find_attribute_value?(parsed_attributes, target_attribute_name)
          if match = parsed_attributes.find { |attribute_name, parsed_attribute| attribute_name == target_attribute_name }
            match[1].val(:Value)
          end
        end

        def self.canonical_hash(hash = {})
          ret = CommonDSL::Parse::CanonicalInput::Hash.new
          hash.each_pair { |k, v| ret.set(k, v) }
          ret
        end
      end
    end
  end
end
