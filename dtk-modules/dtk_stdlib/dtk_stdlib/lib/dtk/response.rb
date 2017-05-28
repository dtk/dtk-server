module DTKModule
  module DTK
    class Response
      attr_reader :hash_form
      def initialize(dynamic_attributes = {})
        @hash_form = ResponseOrErrorHashContent.new(:ok, dynamic_attributes: dynamic_attributes)
      end      

      class Ok < self
      end
    end
  end
end

