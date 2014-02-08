module DTK
  module ModuleDSL
    class ParsingError < ErrorUsage::DSLParsing
      def self.trap(&block)
        ret = nil
        begin
          ret = yield
        rescue ErrorUsage::DSLParsing,ErrorUsage::Parsing => e
          ret = e
        end
        ret
      end

      def self.is_error?(obj)
        obj.is_a?(ErrorUsage::DSLParsing) || 
        obj.is_a?(ErrorUsage::Parsing)
      end
    end
  end
end
