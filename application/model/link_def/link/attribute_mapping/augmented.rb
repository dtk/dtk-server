module DTK; class LinkDef::Link
  class AttributeMapping
    # attribute mapping augmented with context
    class Augmented < Hash
      def initialize(attribute_mapping,input_attr,input_path,output_attr,output_path)
        super()
        @attribute_mapping = attribute_mapping
        merge!(:input_id => input_attr.id,:output_id => output_attr.id)
        merge!(:input_path => input_path) if input_path
        merge!(:output_path => output_path) if output_path
      end

      def parse_function_with_args?()
        @attribute_mapping.parse_function_with_args?()
      end
    end
  end
end; end

