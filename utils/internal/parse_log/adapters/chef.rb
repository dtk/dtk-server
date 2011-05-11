module XYZ
  module ParseLogAdapter
    class Chef
      def self.parse(lines)
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
         {:error => /ERROR:/},
         {:info => /INFO:/}]
      )
      class LogSegments < ::XYZ::LogSegments
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
    end
  end
end
