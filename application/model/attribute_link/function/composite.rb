module DTK; class AttributeLink
  class Function
    class Composite  < WithArgs
      def initialize(function_def,propagate_proc)
        super
        # need to reify constants
        constants[:outer_function]
      end
      def self.composite_link_function(outer_function,inner_expression)
        {
          :function => {
            :name => :composite,
            :constants  => {
              :outer_function => outer_function,
              :inner_expression => inner_expression
            }
          } 
        }
      end

      def internal_hash_form(opts={})
        unless opts.empty?
          raise Error.new("Opts should be empty")
        end
        inner_value = inner_expression.value()
        outer_function.internal_hash_form(:inner_value => inner_value) 
      end

      def value(opts={})
        inner_value = inner_expression.value()
        outer_function.value(:inner_value => inner_value) 
      end
     private
      def inner_expression()
        constants[:inner_expression]
      end
      def outer_function()
        constants[:outer_function]
      end
    end
  end
end; end
