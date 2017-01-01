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
        key_elements = qualified_key.key_elements
        if key_elements.size == 2 and key_elements[0].type.to_sym == :node
          node_name = key_elements[0].key
          assembly_instance.get_node?([:eq, :display_name, node_name]) || 
            fail(Error, "Unexpected that assembly '#{assembly_instance.display_name}' does not have a node with name '#{node_name}'")
        end
      end

      # if node attribute returns [node_name, attribute_name]; otherwise returns nil
      def self.is_node_attribute?(qualified_key)
        key_elements = qualified_key.key_elements
        if key_elements.size == 2 and key_elements[0].type.to_sym == :node and key_elements[1].type.to_sym == :attribute
          node_name      = key_elements[0].key
          attribute_name = key_elements[1].key
          [node_name, attribute_name]
        end
      end

      def self.parent_component_name?(qualified_key, opts = {})
        node_name      = nil
        component_name = nil
        qualified_key.key_elements.each do |element|
          if element[:type] == :component
            component_name = element[:key]
          elsif element[:type] == :node
            node_name = element[:key]
          end
        end
        opts[:include_node] ? "#{node_name}/#{component_name}" : component_name
      end

    end
  end
end
