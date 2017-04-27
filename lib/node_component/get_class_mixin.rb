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
    module GetClassMixin
      def components_with_attributes(components)
        Component::Instance::WithAttributes.components_with_attributes(components)
      end
      
      def component_with_attributes(component)
        components_with_attributes([component]).first
      end
      
      private
      
      def get_components_with_attributes(nodes, assembly)
        components_with_attributes(get_components(nodes, assembly))
      end
      
      COMPONENT_COLS = [:id, :group_id, :display_name, :component_type]
      def get_components(nodes, assembly)
        ret = []
        return ret if nodes.empty?
        internal_names = nodes.map { |node| node_component_ref_from_node(node).gsub(/::/,'__') }
        sp_hash = {
          cols: COMPONENT_COLS,
          filter: [:and, 
                   [:eq, :assembly_id, assembly.id], 
                   [:oneof, :display_name, internal_names]]
        }
          Component::Instance.get_objs(assembly.model_handle(:component), sp_hash)
      end
      
      NODE_COLS = [:id, :group_id, :display_name, :assembly_id]
      def node_from_component(component, assembly)
        sp_hash = {
          cols: NODE_COLS,
          filter: [:and, 
                   [:eq, :assembly_id, assembly.id], 
                   [:eq, :display_name, node_name(component)]]
        }
        Node.get_obj(assembly.model_handle(:node), sp_hash) || 
          fail(Error, "Unexpected that no matching node for componnet '#{component.display_name}'")
      end

    end
  end
end
