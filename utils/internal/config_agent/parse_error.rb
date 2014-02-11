module DTK
  class ConfigAgent
    class ParseError < ErrorUsage::Parsing
      def initialize(msg,opts=Opts.new())
        #TODO: stub to use opts, which can have line or file path
        super(msg)
      end
    end      
  end
end
