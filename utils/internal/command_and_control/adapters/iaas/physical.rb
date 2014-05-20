module DTK
  module CommandAndControlAdapter
    class Physical < CommandAndControlIAAS
      def self.destroy_node?(node,opts={})
        true #vacuously succeeds
      end
    end
  end
end
