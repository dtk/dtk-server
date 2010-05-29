module XYZ
  module EC2
    class Node < EC2AdapterImplementation
      def initialize(node)
        @obj = node
      end
    end
  end
end
