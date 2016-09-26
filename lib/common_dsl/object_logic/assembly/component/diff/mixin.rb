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
  class CommonDSL::ObjectLogic::Assembly::Component::Diff
    module Mixin
      private

      def component_name
        relative_distinguished_name
      end

      def component_title?
        component_type, title = ComponentTitle.parse_component_display_name(component_name)
        title
      end

      # This method will either return a node object if component is under node or node group or nil
      # if component is asembly level
      def parent_node?
        return @parent_node if @parent_node

        key_elements = qualified_key.key_elements
        if key_elements.size == 2 and key_elements[0].type.to_sym == :node and key_elements[1].type.to_sym == :component
          node_name = key_elements[0].key
          unless @parent_node =  assembly_instance.get_node?([:eq, :display_name, node_name])
            fail Error, "Unexpected that assembly '#{assembly_instance.display_name}' does not have a node with name '#{node_name}'"
          end
          @parent_node
        elsif key_elements.size == 1 and key_elements.first.type == :component
          nil # this is assembly level component
        else
          fail Error, "Unexpected form for key_elements: #{key_elements.inspect}"
        end
      end
      
    end
  end
end

