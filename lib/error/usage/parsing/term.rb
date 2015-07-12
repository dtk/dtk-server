module DTK; class ErrorUsage
  class Parsing
    class Term < self
      def initialize(term, type_as_symbol = nil)
        msg =
          if type_as_symbol
            "Cannot parse #{type_print_form(type_as_symbol)} term: #{term}"
          else
            "Cannot parse term: #{term}"
          end
          super(msg)
      end

      private

      def type_print_form(type_as_symbol)
        type_as_symbol.to_s.gsub(/_/, ' ')
      end
    end
  end
end; end
