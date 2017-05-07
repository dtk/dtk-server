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
      class NodeAttribute < self
        ATTRIBUTES_FOR_COMPONENT = ['image', 'size']
        NODE_GROUP_ATTRIBUTE_MAPPING = {
          :type        => 'type',
          :cardinality => 'cardinality'
        }
        NODE_GROUP_ATTRIBUTE_NAMES = NODE_GROUP_ATTRIBUTE_MAPPING.values

        TYPE_GROUP_VALUE = 'group'

        def self.move_attributes_to_node_component!(node_component, parsed_node_or_component)
          return unless parsed_attributes = parsed_node_or_component.val(:Attributes)

          attr_val_pairs = ATTRIBUTES_FOR_COMPONENT.inject({}) do |h, name|
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
          
          # remove from parsed_node_or_component any moved attributes (attr_val_pairs.keys)
          remove_keys!(parsed_node_or_component, :Attributes, attr_val_pairs.keys)
        end

        def self.move_component_node_group_attributes_under_node!(parsed_node, parsed_component)
          overrides = { NODE_GROUP_ATTRIBUTE_MAPPING[:type] => TYPE_GROUP_VALUE }
          move_component_attributes_under_node!(parsed_node, parsed_component, NODE_GROUP_ATTRIBUTE_NAMES, overrides: overrides)
        end
        
        private

        # opts can have keys:
        #  :overrides
        def self.move_component_attributes_under_node!(parsed_node, parsed_component, attribute_names, opts = {})
          overrides = opts[:overrides] || {}
          parsed_attributes = parsed_component.val(:Attributes) || canonical_hash
          attribute_names.each do |name|
            value = (overrides.has_key?(name) ? overrides[name] : find_attribute_value?(parsed_attributes, name))
            set_attribute!(parsed_node, name, value) unless value.nil?
          end
          remove_keys!(parsed_component, :Attributes, attribute_names)
        end
        
        def self.set_attribute!(parsed_node_or_component, attribute_name, value)
          parsed_attributes = parsed_node_or_component.val(:Attributes) || canonical_hash
          parsed_attributes.merge!(attribute_name => canonical_hash(:Value => value))
          parsed_node_or_component.set(:Attributes, parsed_attributes)
          parsed_node_or_component
        end
        
      end
    end
  end
end
