module DTK
  class Node
    module TypeMixin
      def is_node?()
        Type::Node.isa?(get_field?(:type))
      end
      def is_node_group?()
        #short circuit
        return true if (kind_of?(NodeGroup) or kind_of?(ServiceNodeGroup))
        Type::NodeGroupisa?(get_field?(:type))
      end
    end

    class Type
      def self.types()
        Node.types() + NodeGroup.types()
      end
      def self.isa?(type)
        type and types().include?(type.to_sym)
      end
      class Node < self
        Types = [:stub,:instance,:image,:target_ref,:staged]
        Types.each do |type|
          class_eval("def self.#{type}(); '#{type}'; end")
        end
        def self.types()
          Types
        end
      end
      class NodeGroup < self
        Types = [:stub,:instance,:staged]
        Types.each do |type|
          class_eval("def self.#{type}(); 'node_group_#{type}'; end")
        end
        def self.types()
          Types
        end
      end
    end
  end
end
