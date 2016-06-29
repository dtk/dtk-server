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
  class CommonModule::BaseService
    module NodePropertyComponent
      # For each node, it creates a node_property_component if needed using the relevant nod attributes in paresd node
      def self.create_node_property_components?(parsed_nodes)
        parsed_nodes.each do |parsed_node|
          node_property_component = find_or_add_node_property_component!(parsed_node)
          if parsed_attributes = parsed_node.val(:Attributes)
            attr_val_pairs = {
              'image' => find_attribute_value?(parsed_attributes, 'image'),
              'size'  => find_attribute_value?(parsed_attributes, 'size')
            }
            update_attributes_in_node_property_component!(node_property_component, attr_val_pairs)
          end
        end
      end
      
      private

      def self.find_attribute_value?(parsed_attributes, attribute_name)
        if match = parsed_attributes.find { |parsed_attribute| attribute_name == parsed_attribute.req(:Name) }
          match.val(:Value)
        end
      end

      # TODO: DTK-2554: Aldin: all this routines need to be updated when dtk-dsl updated
      #  and rename var 'components' to 'parsed_components'

      def self.find_or_add_node_property_component!(parsed_node)
        ret = nil
        node_property_component_name = CommandAndControl.node_property_component
        if match = matching_node_property_component?(parsed_node, node_property_component_name)
          ret = match
        else
          ret = node_property_component_hash_form(node_property_component_name)
          (parsed_node['components'] ||= []) << ret
        end
        ret
      end

      def self.matching_node_property_component?(parsed_node, node_property_component_name)
        components = parsed_node['components'] ||= []
        # TODO: DTK-2554: Aldin: when converted below line not needed since parsed will make sure an array
        unless components.is_a?(Array)
          components = parsed_node['components'] = [components]
        end
        # Today: parsing will normailze this so components elements are parsed_component elements
        components.each_with_index do |component, i|
          component_name = component.is_a?(Hash) ? component.keys.first : component
          if component_name == node_property_component_name
            # convert if not in hash form
            unless component.is_a?(Hash)
              components[i] = node_property_component_hash_form(node_property_component_name)
            end
            return components[i]
          end
        end
        nil
      end

      # TODO: DTK-2554: Aldin
      # This is using old form of attribues
      # {name1 => v1, bname2 => val2}
      # when convert import nodes over will change to
      # attributes being an array with element slike {:name=>"image", :value=>"amazon_hvm"}
      # node_property_component wil be in hash form
      def self.update_attributes_in_node_property_component!(node_property_component, attr_val_pairs)
        attributes = node_property_component.values.first['attributes']
        attr_val_pairs.each_pair do |attr_name, attr_val|
          attributes.merge!(attr_name =>  attr_val) unless attr_val.nil?
        end
      end

      def self.node_property_component_hash_form(obj)
        obj.kind_of?(Hash) ? obj : { obj => { 'attributes' => {} } }
      end

    end
  end
end
