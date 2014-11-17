module DTK; class AttributeLink
  class Function
    class Composite  < WithArgs
      def initialize(function_def,propagate_proc)
        super
        # need to reify constants
        reify_constant!(:outer_function,propagate_proc)
        reify_constant!(:inner_expression,propagate_proc)
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
      def reify_constant!(constant_name,propagate_proc)
        nested_function_def = constants[constant_name]
        nested_fn_name = self.class.function_name(nested_function_def)
        nested_klass = self.class.klass(nested_fn_name)
        constants[constant_name] = nested_klass.new(nested_function_def,propagate_proc)
      end

      def inner_expression()
        constants[:inner_expression]
      end
      def outer_function()
        constants[:outer_function]
      end
    end
  end
end; end
