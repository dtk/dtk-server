module DTK; class AttributeLink
  class Function
    class VarEmbeddedInText < WithArgs
      def initialize(function_def,propagate_proc)
        super
        @text_parts = function_hash[:constants][:text_parts]
      end
    
      # TODO: remove
      def internal_hash_form(opts={})
        {:value_derived => value()}
      end

      def value(opts={})
        val = nil
        var = output_value(opts)
        # alternative sematics is to treat nil like var with empty string
        return val if var.nil?
        
        text_parts = @text_parts.dup
        val = text_parts.shift
        text_parts.each do |text_part|
          val << var
          val << text_part
        end
        val
      end
    end
  end
end; end
