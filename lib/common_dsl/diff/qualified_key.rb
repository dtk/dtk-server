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
  class CommonDSL::Diff
    class QualifiedKey < ::DTK::DSL::QualifiedKey 

      # If this refers to element under a node than node object wil be returned; otherwise nil will be returned
      # if component is asembly level
      def self.parent_node?(qualified_key, assembly_instance)
        if parent_key_elements = parent_key_elements?
          if node_name = node_name_if_node?(parent_key_elements.last)
            assembly_instance.get_node?([:eq, :display_name, node_name]) || 
              fail(Error, "Unexpected that assembly '#{assembly_instance.display_name}' does not have a node with name '#{node_name}'")
          end
        end
      end

      # TODO: DTK-2938; think below shoudl be written in terms of parent_node? or its subfunctions node_name_if_node?(
      # if node attribute returns [node_name, attribute_name]; otherwise returns nil
      def self.is_node_attribute?(qualified_key)
        key_elements = qualified_key.key_elements
        if key_elements.size == 2 and key_elements[0].type.to_sym == :node and key_elements[1].type.to_sym == :attribute
          node_name      = key_elements[0].key
          attribute_name = key_elements[1].key
          [node_name, attribute_name]
        end
      end

      ParentComponentInfo = Struct.new(:component_name, :node_name)
      def parent_component_info
        parent_key_elements   = parent_key_elements? || fail("Unexpected that (#{self.inspect}) has no parent")

        component_key_element = parent_key_elements.last 
        fail "Unexpected that parent_key_elements.last is not a component" unless component_key_element[:type] == :component
        component_name = component_key_element[:key]

        node_name = nil
        if parent_key_elements.size > 1
          node_key_element = parent_key_elements.last(2)[0]
          node_name = node_name_if_node?(node_key_element) || fail("Unexpected that node_key_element is not a node")
        end
        ret = ParentComponentInfo.new(component_name, node_name)
        pp ret
        ret
      end

      private 

      def parent_key_elements?
        if key_elements.size > 1
          key_elements[0..key_elements.size-2]
        end
      end

      def node_name_if_node?(key_element)
        if key_element[:type] == :node 
          key_element[:key]
        elsif node_name = node_name_if_node_component?(key_element)
          node_name
        end
      end
      
      def node_name_if_node_component?(key_element)
        if key_element[:type] == :component
          NodeComponent.node_name_if_node_component?(key_element[:key])
        end
      end

    end
  end
end
