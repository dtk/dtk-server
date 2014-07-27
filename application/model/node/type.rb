module DTK
  class Node
    module TypeMixin
      def is_node?()
        Type::Node.isa?(get_field?(:type))
      end
      def is_node_group?()
        # short circuit
        return true if (kind_of?(NodeGroup) or kind_of?(ServiceNodeGroup))
        Type::NodeGroup.isa?(get_field?(:type))
      end
      def node_group_model_name()
        unless is_node_group?()
          raise Error.new("Should not be called if not a node group")
        end
        Type::NodeGroup.model_name(get_field?(:type))
      end
    end

    class Type
      def self.types()
        Node.types() + NodeGroup.types()
      end
      def self.isa?(type)
        type and types().include?(type.to_sym)
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

      class Node < self
        Types = 
          [
           :stub,              # - in an assembly template
           :image,             # - corresponds to an IAAS, hyperviser or container image
           :instance,          # - in a service instance where it correspond to an actual node
           :staged,            # - in a service instance before actual node correspond to it
           :target_ref,        # - target_ref to actual node
           :target_ref_staged  # - target_ref to node not created yet
          ]
        Types.each do |type|
          class_eval("def self.#{type}(); '#{type}'; end")
        end
        def self.types()
          Types
        end
      end

      class NodeGroup < self
        Types = 
          [
           :stub,     # - in an assembly template
           :instance, # - in a service instance where actual nodes correspond to it
           :staged    # - in a service instance before actual nodes correspond to it
          ]
        def self.types()
          @types ||= Types.map{|r|type_from_name(r)}
        end

        def self.model_name(type)
          case type.to_sym
            when :node_group_stub,:node_group_staged then :service_node_group
            when :node_group_instance then :node_group
            else raise Error.new("Unexpected node group type (#{type})")
          end
        end

       private
        def self.type_from_name(type_name)
          "node_group_#{type_name}".to_sym
        end
        Types.each do |type_name|
          class_eval("def self.#{type_name}(); '#{type_from_name(type_name)}'; end")
        end
      end
    end
  end
end
