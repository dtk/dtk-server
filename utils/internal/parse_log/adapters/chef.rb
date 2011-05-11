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
                self[error_segment_pos] = err.new(error_segment,self)
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
          log_segment.aux_data.each do |l|
            unless l.empty?
              return l =~ /Chef::Mixin::Template::TemplateError/
            end
          end
          nil
        end
        attr_reader :template_file_ref,:error_line_num,:error_lines,:error_detail
        def initialize(log_segment,all_segments)
          super(:template_error)
          @template_file_ref = nil
          @error_line_num = nil
          @error_detail = nil
          @error_lines = Array.new
          parse!(log_segment,all_segments)
        end
       private
        def parse!(log_segment,all_segments)
          @template_file_ref = ChefFileRef.find_chef_template(all_segments[all_segments.size-2])
          state = :init
          log_segment.aux_data.each do |l|
            return if state == :setting_error_lines and l.empty?
            next if l.empty?
            if state == :init
              if l =~ /Chef::Mixin::Template::TemplateError/
                state = :error_found
                if l =~ /on line #([0-9]+):/
                  @error_line_num = $1.to_i
                end
                if l =~ /TemplateError \((.+) for #<Erubis::Context/
                  @error_detail = $1
                end
              end
            elsif [:error_found,:setting_error_lines].include?(state)
              if l =~ /[0-9]+:/
                @error_lines << l
                state = :setting_error_lines
              end
            end
          end
        end
      end
      #complication is taht may not have uniq handle on file
      class ChefFileRef < HashObject
        def self.find_chef_template(segment)
          if segment.line =~ /looking for template (.+) in cookbook :(.+$)/
            hash = {
              :cookbook => $2,
              :file_name => $1
            }
            self.new(hash)
          end
        end
      end

      PossibleErrors = [ErrorTemplate]
    end
  end
end
