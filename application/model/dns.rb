module DTK
  class DNS
    class Assignment
      attr_reader :address
      def initialize(address)
        @address = address
      end
    end
    r8_nested_require('dns', 'r8')
  end
end
