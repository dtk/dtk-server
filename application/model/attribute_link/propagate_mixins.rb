module DTK; class AttributeLink
  module Propagate
    module Mixin
      def input_value
        @input_attr[:value_derived]
      end

      def input_semantic_type
        SemanticType.create_from_attribute(@input_attr)
      end

      def output_value(opts={})
        if opts.key?(:inner_value)
          opts[:inner_value] 
        else 
          @output_attr[:value_asserted] || @output_attr[:value_derived]
        end
      end

      def output_semantic_type
        SemanticType.create_from_attribute(@output_attr)
      end
    end
  end
end; end

