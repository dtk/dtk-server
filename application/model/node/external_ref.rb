module DTK
  class Node
    class ExternalRef
      module Mixin
        def update_external_ref_field(ext_ref_field,val)
          update_hash_key(:external_ref,ext_ref_field,val)
        end
        def refresh_external_ref!()
          self.delete(:external_ref)
          get_field?(:external_ref)
        end

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
