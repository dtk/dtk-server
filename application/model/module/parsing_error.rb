module DTK
  module Module
    class ParsingError
      def self.trap(&block)
        parsing_error = nil
        begin
          normal_return = yield
        rescue ErrorUsage::DSLParsing,ErrorUsage::Parsing => e
          parsing_error = e
        end
        parsing_error
      end

      def self.is_error?(obj)
        obj.is_a?(ErrorUsage::DSLParsing) || 
        obj.is_a?(ErrorUsage::Parsing)
      end
    end
  end
end
