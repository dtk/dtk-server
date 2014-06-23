module DTK
  class Node
    class ExternalRef
      module Mixin
        def external_ref()
          ExternalRef.new(self)
        end
      end
      
      def initialize(node)
        @node = node
      end
      
      def references_image?(target)
        CommandAndControl.references_image?(target,external_ref())
      end

     private
      def external_ref()
        @node.get_field?(:external_ref)||{}
      end
    end
  end
end
