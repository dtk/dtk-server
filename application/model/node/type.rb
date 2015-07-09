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
        return true if (is_a?(NodeGroup) || is_a?(ServiceNodeGroup))
        Type::NodeGroup.isa?(get_field?(:type))
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
