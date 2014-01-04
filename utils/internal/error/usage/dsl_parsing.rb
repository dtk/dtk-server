module DTK
  class ErrorUsage
    class DSLParsing < self #comes from dtk-commin/lib/dsl/file_parser
      class YAMLParsing < self
      end

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

