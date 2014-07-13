module DTK; class NodeBindings
  class DSL
    class ParseInput
      attr_reader :input
      def initialize(input_ruby_object)
        @input = input_ruby_object
      end
      def type?(klass)
        @input.kind_of?(klass)
      end
      def error(msg)
        input_param = ErrorUsage::Parsing::Params.new(:input => @input)
        ServiceModule::ParsingError.new(msg,input_param)
      end
    end
  end
end; end

