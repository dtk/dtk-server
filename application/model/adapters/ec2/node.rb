module XYZ
  module EC2
    class Node < AdapterImplementation
      def initialize(node)
        @obj = node
      end
    end
  end
end
