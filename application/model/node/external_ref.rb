module DTK
  class Node
    class ExternalRef
      module Mixin
        def external_ref()
          ExternalRef.new(self)
        end
      end

      attr_reader :hash
      def initialize(node)
        @node = node
        @hash = @node.get_field?(:external_ref)||{}
      end
      
      def references_image?(target)
        CommandAndControl.references_image?(target,hash())
      end
    end
  end
end
