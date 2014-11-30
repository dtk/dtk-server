module DTK; class LinkDefLink
  class AttributeMapping
    class AugmentedLink < Hash
      def initialize(aug_link_context)
        cntx = aug_link_context # for succinctness
        super()
        @attribute_mapping = cntx.attribute_mapping
        merge!(:input_id => cntx.input_attr[:id],:output_id => cntx.output_attr[:id])
        merge!(:input_path => cntx.input_path) if cntx.input_path
        merge!(:output_path => cntx.output_path) if cntx.output_path
      end
      private :initialize

      def self.ret_link(aug_link_context)
        new(aug_link_context)
      end

      def parse_function_with_args?()
        @attribute_mapping.parse_function_with_args?()
      end
    end
  end
end; end

