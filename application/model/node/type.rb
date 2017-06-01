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
module DTK; class Node
  class Type
    r8_nested_require('type', 'node')
    r8_nested_require('type', 'node_group')

    module Mixin
      def is_node?
        Type::Node.isa?(get_field?(:type))
      end

      def is_node_group?
        # short circuit
        return true if (is_a?(NodeGroup) || is_a?(NodeGroup))
        Type::NodeGroup.isa?(get_field?(:type))
      end

      def is_staged?()
        type = get_field?(:type)
        Type::Node.is_staged?(type) or Type::NodeGroup.is_staged?(type)
      end

      def node_group_model_name
        unless is_node_group?()
          fail Error.new('Should not be called if not a node group')
        end
        Type::NodeGroup.model_name(get_field?(:type))
      end
    end

    def self.types
      Node.types() + NodeGroup.types()
    end
    def self.isa?(type)
      type && types().include?(type.to_sym)
    end

    def self.new_type_when_create_node(node)
      type = node.get_field?(:type)
        ret =
        case type
        when Node.staged then Node.instance
        when Node.target_ref_staged then Node.target_ref
        end
      unless ret
        Log.error("Unexpected type on node being created: #{type}")
        #best guess so does not completely fail
        ret = (node.is_node_group? ? NodeGroup.instance : Node.instance)
      end
      ret
    end
  end
end; end