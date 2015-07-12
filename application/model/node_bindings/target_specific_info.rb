module DTK
  class NodeBindings
    class TargetSpecificInfo
      attr_accessor :image_id, :size
      def initialize(node_target)
        @node_target = node_target
      end

      def node_target_image?
        @node_target.respond_to?(:image) && @node_target.image
      end
    end
  end
end
