module XYZ
  module ParseLogAdapter
    class Chef
      def self.parse(lines)
        ret = LogSegments.new
        current_segment = nil
        lines.each do |line|
          if match = Pattern.find{|k,pat|line =~ pat}
            ret << current_segment if current_segment
            current_segment = LogSegment.create(match[0],line)
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
     public
      class LogSegments < ::XYZ::LogSegments
        def post_process!()
          #if an error then this is repeated; so cut off
          error_segment_pos = cut_off_after_error!()
          if error_segment_pos
            error_segment = self[error_segment_pos]
            PossibleErrors.each do |err|
              if err.isa?(error_segment)
                self[error_segment_pos] = err.new(error_segment)
                break
              end
            end
          end
          self
        end
        private
        #if an error cuts off after error and returns the error segment position
        def cut_off_after_error!()
          pos = nil
          self.each_with_index do |seg,i|
            if seg.type == :error
              pos = i
              break
            end
          end
          if pos
            slice!(pos+1,size-pos)
            pos
          end
        end
      end
      class ErrorTemplate < ::XYZ::LogSegmentError 
        def self.isa?(log_segment)
          #TODO stub
          true
        end
        def initialize(log_segment)
          super(:template_error)
        end
      end

      PossibleErrors = [ErrorTemplate]
    end
  end
end
