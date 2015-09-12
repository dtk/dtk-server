module DTK; class ErrorUsage
  class Parsing
    class WrongType < self
      def initialize(object, legal_values = [], &legal_values_block)
        super(*LegalValues.reify(legal_values, &legal_values_block).error_message_and_params(object))
      end
    end
  end
end; end
