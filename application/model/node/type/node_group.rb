module DTK; class Node
  class Type
    class NodeGroup < self
      Types =
          [
           :stub,     # - in an assembly template
           :instance, # - in a service instance where actual nodes correspond to it
           :staged    # - in a service instance before actual nodes correspond to it
          ]
      def self.types
          @types ||= Types.map { |r| type_from_name(r) }
      end

      def self.model_name(type)
        case type.to_sym
        when :node_group_stub, :node_group_staged then :service_node_group
        when :node_group_instance then :node_group
        else fail Error.new("Unexpected node group type (#{type})")
        end
      end

      StagedTypes = [:staged]
      def self.is_staged?(type)
        StagedTypes.include?(type.to_sym)
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
end; end
