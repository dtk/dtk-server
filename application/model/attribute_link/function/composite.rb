module DTK; class AttributeLink
  class Function
    class Composite  < WithArgs
      def internal_hash_form(opts={})
        unless opts.empty?
          raise Error.new("Opts should be empty")
        end
        inner_value = @inner_expression.value()
        @outer_function.internal_hash_form(:inner_value => inner_value) 
      end

      def value(opts={})
        inner_value = @inner_expression.value()
        @outer_function.value(:inner_value => inner_value) 
      end
    end
  end
end; end
