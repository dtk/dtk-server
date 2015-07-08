module DTK
  class ConfigAgent
    class ParseError < ErrorUsage::Parsing
      def initialize(msg_x,opts={})
        msg =
          if line_num = opts[:line_num]
            "#{msg_x} (on line #{line_num})"
          else
            msg_x
          end
        super(msg,opts)
      end
    end
  end
end
