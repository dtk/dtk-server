module DTK; class LinkDef::Link; class AttributeMapping
  module ParseHelper
    module VarEmbeddedInText
      def self.isa?(am)
        if output_term_index = (am[:output] || {})[:term_index]
          if output_var = output_term_index.split('.').last
            # example abc${output_var}def",
            if output_var =~ /(^[^\$]*)\$\{[^\}]+\}(.*$)/
              text_parts = [$1, $2]
              {
                name: :var_embedded_in_text,
                constants: { text_parts: text_parts }
              }
            end
          end
        end
      end
    end
  end
end; end; end
