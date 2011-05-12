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
         {:info_error => /INFO: error:/},
         {:info_backtrace => /INFO: backtrace:/},
         {:info => /INFO:/}]
      )
     public
      class LogSegments < ::XYZ::LogSegments
        def pp_form_summary()
          if @complete
            if last.type == :error
              "complete with error\n" + Aux::pp_form(last)
            else
              "complete and ok\n"
            end
          else
            if last.type == :error
              "incomplete with error\n" + Aux::pp_form(last)
            else
              "incomplete and no error yet\n"
            end
          end
        end
        def post_process!()
          @complete = complete?()
          error_pos =  find_error_position()
          return self unless error_pos
          segments_from_error = self[error_pos,1+size-error_pos]
          prev_segment =  self[error_pos-1]
          #try to find specific error
          specific_error = nil
          PossibleErrors.each do |err|
            if err.isa?(segments_from_error)
              specific_error = err.new(segments_from_error,prev_segment)
              break
            end
          end

          #cut off everything after error and replace last item with specfic error
          slice!(error_pos+1,size-error_pos)
          self[error_pos] = specific_error if specific_error
          self
        end
       private
        def complete?()
          return false if empty?
          return true if last.line =~ /handlers complete/
          return false if size < 2
          self[size-2].line  =~ /handlers complete/ ? true : false
        end

        def find_error_position()
          each_with_index{|seg,i|return i if seg.type == :error}
          nil
        end
      end
      class ErrorTemplate < ::XYZ::LogSegmentError 
        def self.isa?(segments_from_error)
          segments_from_error.first.aux_data.each do |l|
            return l =~ /Chef::Mixin::Template::TemplateError/ unless l.empty?
          end
          nil
        end
        def initialize(segments_from_error,prev_segment)
          super(:template_error)
          parse!(segments_from_error,prev_segment)
        end
       private
        def parse!(segments_from_error,prev_segment)
          @error_file_ref = ChefFileRef.find_chef_template(prev_segment)
          state = :init
          segments_from_error.first.aux_data.each do |l|
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
      #TODO: this is runtime vs syntactic error
      class ErrorRecipe < ::XYZ::LogSegmentError 
        def self.isa?(segments_from_error)
          line = segments_from_error.first.line
          line =~ Regexp.new("#{RecipeCache}[^/]+/recipes")
        end
        def initialize(segments_from_error,prev_segment)
          super(:recipe_error)
          parse!(segments_from_error)
        end
       private
        RecipeCache = "/var/chef/cookbooks/"
        def parse!(segments_from_error)
          line = segments_from_error.first.line
          if line =~ Regexp.new("#{RecipeCache}([^/]+)/recipes/([^:]+):([0-9]+):in `from_file'")
            cookbook = $1
            recipe_filename = $2
            @error_line_num = $3.to_i 
            @error_file_ref = ChefFileRef.recipe(cookbook,recipe_filename)
          end
          @error_detail = segments_from_error.first.aux_data.first
        end
      end
      #complication is that may not have uniq handle on file
      class ChefFileRef < HashObject
        def self.find_chef_template(segment)
          if segment.line =~ /looking for template (.+) in cookbook :(.+$)/
            hash = {
              :type => :template,
              :cookbook => $2,
              :file_name => $1
            }
            self.new(hash)
          end
        end
        def self.recipe(cookbook,recipe_filename)
          hash = {
            :type => :recipe,
            :cookbook => cookbook,
            :file_name => recipe_filename
          }
          self.new(hash)
        end
      end

      PossibleErrors = [ErrorTemplate,ErrorRecipe]
    end
  end
end
