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
      def parent_node?(assembly_instance)
        return @parent_node if @parent_node
        if key_elements.size == 2 and key_elements[0].type.to_sym == :node
          node_name = key_elements[0].key
          unless @parent_node = assembly_instance.get_node?([:eq, :display_name, node_name])
            fail Error, "Unexpected that assembly '#{assembly_instance.display_name}' does not have a node with name '#{node_name}'"
          end
          @parent_node
        end
      end

      def parent_node(assembly_instance)
        parent_node?(assembly_instance) || fail(Error, "Unexepected that parent_node?(assembly_instance) is nil")
      end

      # temp workaround for node = parent_node?
      def self.parent_node?(key, assembly_instance)
        if key.respond_to?(:parent_node?)
          key.parent_node?(assembly_instance)
        else
          new(key.key_elements).parent_node?(assembly_instance)
        end
      end

      # if node attribute returns [node_name, attribute_name]; otherwise returns nil
      def is_node_attribute?
        if key_elements.size == 2 and key_elements[0].type.to_sym == :node and key_elements[1].type.to_sym == :attribute
          node_name      = key_elements[0].key
          attribute_name = key_elements[1].key
          [node_name, attribute_name]
        end
      end

      private
      attr_reader :key_elements

    end
  end
end
