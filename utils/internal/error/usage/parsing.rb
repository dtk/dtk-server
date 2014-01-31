#TODO: cleanup; complication is that DSLParsing intesrsects with dtk common classes
module DTK
  class ErrorUsage 
    class Parsing < self
      def initialize(error_msg,file_path=nil)
        super(error_msg,file_path)
      end

      class YAML < self
      end
      class Term < self
        def initialize(term,type_as_symbol=nil)
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
          type_as_symbol.to_s.gsub(/_/,' ')
        end
      end
    end

    class DSLParsing < self
      include DSLParsingAux

      def self.raise_error_unless(object,legal_values_input_form=[],&legal_values_block)
        legal_values = LegalValues.reify(legal_values_input_form,&legal_values_block)
        unless legal_values.match?(object)
          raise WrongType.new(object,legal_values,&legal_values_block)
        end
      end
      
      class WrongType < self
        def initialize(object,legal_values=[],&legal_values_block)
          super(LegalValues.reify(legal_values,&legal_values_block).error_message(object))
        end
      end
    end
  end
end
