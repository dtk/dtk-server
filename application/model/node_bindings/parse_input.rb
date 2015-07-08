module DTK
  class NodeBindings
    class ParseInput
      attr_reader :input
      def initialize(input,opts={})
        @input = (opts[:content_field] ? ContentField.new(input) : input)
      end

      def child(input)
        self.class.new(input,content_field: @input.is_a?(ContentField))
      end

      def type?(klass)
        @input.is_a?(klass)
      end

      def error(msg)
        input_param = ErrorUsage::Parsing::Params.new(input: @input)
        ServiceModule::ParsingError.new(msg,input_param)
      end
    end

    class ContentField < Hash
      def initialize(content_hash)
        super()
        replace(content_hash)
      end
    end
  end
end

