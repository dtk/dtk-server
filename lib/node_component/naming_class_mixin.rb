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
    module NamingClassMixin
      NODE_COMPONENT_COMPONENT = 'node'
      COMPONENT_TYPE_DELIM = '__'
      COMPONENT_TYPE_DISPLAY_NAME_DEMILM = '::'
      def node_component_type(iaas_type)
        "#{iaas_type}#{COMPONENT_TYPE_DELIM}#{NODE_COMPONENT_COMPONENT}"
      end

      def node_component_type_display_name(iaas_type)
        "#{iaas_type}#{COMPONENT_TYPE_DISPLAY_NAME_DEMILM}#{NODE_COMPONENT_COMPONENT}"
      end
      
      def node_component_ref(iaas_type, node_name)
        "#{node_component_type_display_name(iaas_type)}[#{node_name}]"
      end

      ASSEMBLY_WIDE_NODE_NAME = 'assembly_wide'
      def node_component_ref_from_node(node)
        # TODO: DTK-2967: below hard-wired to ec2
        node.is_assembly_wide_node? ? ASSEMBLY_WIDE_NODE_NAME : node_component_ref(:ec2, node.display_name)
      end

      private

      def iaas_type(component)
        component.get_field?(:component_type).split(COMPONENT_TYPE_DELIM).first.to_sym
      end

    end
  end
end
