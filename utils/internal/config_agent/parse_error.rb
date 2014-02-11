module DTK
  class ConfigAgent
    class ParseError < ErrorUsage
      attr_reader :msg, :filename, :file_asset_id, :line
      def initialize(msg,file_path=nil,line=nil)
        @msg = msg
        @filename = filename
        @line = line
      end
      
      def to_s()
        [:msg, :filename, :file_asset_id, :line].map do |k|
          val = send(k)
          "#{k}=#{val}" if val
        end.compact.join("; ")
      end
    end
  end
end
