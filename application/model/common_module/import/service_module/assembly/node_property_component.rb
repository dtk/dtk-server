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
  class CommonModule
    module Import::ServiceModule::Assembly
      module NodePropertyComponent
        # For each node, it creates a node_property_component if needed using the relevant node attributes in paresd node
        def self.create_node_property_components?(parsed_nodes)
          parsed_nodes.each do |name, parsed_node|
            node_property_component = find_or_add_node_property_component!(parsed_node)
            ec2_node_component = find_or_add_ec2_node_component!(parsed_node)
            if parsed_attributes = parsed_node.val(:Attributes)
              attr_val_pairs = {
                'image' => find_attribute_value?(parsed_attributes, 'image'),
                'size'  => find_attribute_value?(parsed_attributes, 'size')
              }
              update_attributes_in_node_property_component!(node_property_component, attr_val_pairs)
            end
          end
        end
        
        def self.node_bindings_from_node_property_component(cmps, container_idh)
          nb_name          = nil
          node_binding     = nil
          nb_rs_containter = Library.get_public_library(container_idh.createMH(:library))
          
          cmps.each do |cmp|
            if cmp.is_a?(Hash) && cmp.keys.first.eql?(CommandAndControl.node_property_component)
              if attributes = cmp.values.first['attributes']
                size = attributes['size']
                image = attributes['image']
                nb_name = "#{image}-#{size}" if size && image
              end
              break
            end
          end
          
          if nb_name
            filter = [:eq, :ref, nb_name]
            node_bindings = nb_rs_containter.get_node_binding_rulesets(filter)
            node_binding = node_bindings.first[:id] unless node_bindings.empty?
          end
          
          node_binding
        end
        
        private
        
        def self.find_attribute_value?(parsed_attributes, target_attribute_name)
          if match = parsed_attributes.find { |attribute_name, parsed_attribute| attribute_name == target_attribute_name }
            match[1].val(:Value)
          end
        end
        
        def self.find_or_add_node_property_component!(parsed_node)
          ret = nil
          node_property_component_name = CommandAndControl.node_property_component
          if match = matching_node_property_component?(parsed_node, node_property_component_name)
            ret = match
          else
            ret = canonical_hash.merge(node_property_component_name => canonical_hash)
            unless parsed_components = parsed_node.val(:Components)
              parsed_components = canonical_hash
              parsed_node.set(:Components, parsed_components)
            end
            parsed_components.merge!(ret)
          end
          ret
        end

        def self.find_or_add_ec2_node_component!(parsed_node)
          ret = nil
          # ec2_node_component = "#{CommandAndControl.ec2_node_component}"
          ec2_node_component = "#{CommandAndControl.ec2_node_component}[#{parsed_node.name}]"
          if match = matching_node_property_component?(parsed_node, ec2_node_component)
            ret = match
          else
            ret = canonical_hash.merge(ec2_node_component => canonical_hash)
            unless parsed_components = parsed_node.val(:Components)
              parsed_components = canonical_hash
              parsed_node.set(:Components, parsed_components)
            end
            parsed_components.merge!(ret)
          end
          ret
        end
        
        def self.matching_node_property_component?(parsed_node, node_property_component_name)
          if match_in_array_form = (parsed_node.val(:Components) || {}).find { |name, parsed_component| name == node_property_component_name }
            canonical_hash.merge(node_property_component_name => match_in_array_form[1])
          end
        end

        def self.update_attributes_in_node_property_component!(node_property_component, attr_val_pairs)
          unless attributes = node_property_component.val(:Attributes)
            attributes = canonical_hash
            node_property_component.values.first.set(:Attributes, attributes)
          end
          attr_val_pairs.each_pair do |attr_name, attr_val|
            attributes.merge!(attr_name => canonical_hash(:Value => attr_val)) unless attr_val.nil?
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
