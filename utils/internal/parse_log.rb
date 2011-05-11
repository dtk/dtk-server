module XYZ
  class ParseLog
    def self.break_into_segments(lines)
      ret = LogSegments.new
      current_segment = nil
      lines.each do |line|
        if match = Pattern.find{|k,pat|line =~ pat}
          ret << current_segment if current_segment
          current_segment = LogSegment.new(match[0],line)
        elsif current_segment
          current_segment << line 
        end
      end
      ret << current_segment if current_segment
      ret.post_process!()
    end
   private
    #order is important because of subsumption
    Pattern =  Aux::ordered_hash(
      [{:debug => /DEBUG:/},
#       {:backtrace => /INFO:  backtrace:/},
       {:error => /ERROR:/},
       {:info => /INFO:/}]
    )
  end
  class LogSegments < Array
    def post_process!()
      #if an error then this is repeated; so cut off
      cut_off_after_error!()
      self
    end
   private
    def cut_off_after_error!()
      pos = nil
      self.each_with_index do |seg,i|
        if seg.type == :error
          pos = i
          break
        end
      end
      self.slice!(pos+1,size-pos) if pos
      self
    end
  end

  class LogSegment 
    attr_reader :type,:line,:aux_data
    def initialize(type,line)
      @type = type
      @line = line 
      @aux_data = Array.new
    end
    def <<(line)
      @aux_data << line
    end
  end
end
