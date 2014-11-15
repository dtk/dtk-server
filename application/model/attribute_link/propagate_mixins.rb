module DTK; class AttributeLink
  module Propagate
    module Mixin
      def input_value()
        @input_value ||= @input_attr[:value_derived]
      end
      def input_semantic_type()
        @input_semantic_type ||= SemanticType.create_from_attribute(@input_attr)
      end
      
      def output_value()
        @output_value ||= output_value_aux()
      end
      def output_value_aux()
        @output_attr[:value_asserted]||@output_attr[:value_derived]
      end
      def output_semantic_type()
        @output_semantic_type ||= SemanticType.create_from_attribute(@output_attr)
      end
    end
  end
end; end

