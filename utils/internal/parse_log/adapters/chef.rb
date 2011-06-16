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
      
      def self.log_complete?(lines)
        #TODO: if need more specific strings to look for
        # /ERROR: Exception handlers complete/ or /INFO: Report handlers complete/ 
        lines.reverse_each do |l|
          return true if l =~ /handlers complete/
        end
        nil
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

        #TODO: may use just for testing; if so deprecate
        def pp_form_summary()
          if @complete
            if has_error?()
              error_segment = error_segment()
              "complete with error\n" + (error_segment ? Aux::pp_form(error_segment) : "")
            else
              "complete and ok\n"
            end
          else
            if has_error?()
              error_segment = error_segment()
              "incomplete with error\n" + (error_segment ? Aux::pp_form(error_segment) : "")
            else
              "incomplete and no error yet\n"
            end
          end
        end

        def post_process!()
          @complete = complete?()
          return self unless @complete
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
        def ret_file_asset_if_error(model_handle)
          if has_error?()
            error_segment = error_segment()
            error_segment && error_segment.ret_file_asset(model_handle)
          end
        end

        def error_segment()
          last if @complete and last.kind_of?(::XYZ::LogSegmentError)
        end

        def has_error?()
          if @complete
            #short circuit when complete
            last.type == :error
          else
            find{|s|s.type == :error}
          end
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

      class ErrorChefLog < ::XYZ::LogSegmentError
        def initialize(segments_from_error,prev_segment)
          super()
          parse!(segments_from_error,prev_segment)
        end
      end

      class ErrorGeneric < ErrorChefLog 
        def self.isa?(segments_from_error)
          true
        end
       private
        def parse!(segments_from_error,prev_segment)
          segment = segments_from_error[0]
          if segment.line =~ /ERROR: (.+$)/
            @error_detail = $1
          end
        end
      end

      class ErrorTemplate < ErrorChefLog 
        def self.isa?(segments_from_error)
          line = segments_from_error[0].line
          line =~ /ERROR: template/
        end
       private
        def parse!(segments_from_error,prev_segment)
          detail = nil
          if segments_from_error.size > 2 
            line = segments_from_error[2].line
            if line =~ /INFO: error: Chef::Mixin::Template::TemplateError: (.+) for #/
              detail = $1
            end
          end

          @error_detail = "template error" + (detail ? ": #{detail}" : "")
          line = segments_from_error[0].line
          template_resource = line =~ /template\[([^\]]+)\]/ && $1
          recipe = line =~ /template\[[^\]]+\] \((.+) line/ && $1
          @error_lines << "template resource: #{template_resource}" if template_resource
          @error_lines << "called from recipe: #{recipe}" if recipe
        end
      end

      class ErrorService < ErrorChefLog 
        def self.isa?(segments_from_error)
          return nil unless segments_from_error.size > 1
          line = segments_from_error[0].line
          line =~ /ERROR: service/
        end
       private
        def parse!(segments_from_error,prev_segment)
          line = segments_from_error[0].line
          if line =~ /ERROR: (.+$)/
            @error_detail = $1
          end
          return unless segments_from_error.size > 2
          segment = segments_from_error[2]
          if segment.line =~ /INFO: error: Chef::Exceptions::Exec/
            @error_lines = segment.aux_data
          end
        end
      end

      #TODO: this is runtime vs syntactic error
      class ErrorRecipe < ErrorChefLog 
        def self.isa?(segments_from_error)
          line = segments_from_error.first.line
          return true if line =~ Regexp.new("#{RecipeCache}[^/]+/recipes") #TODO: is this still a 0.10 error form?
          return true if line =~ Regexp.new("has had an error")
          nil
        end
       private
        RecipeCache = "/var/chef/cookbooks/"
        def parse!(segments_from_error,prev_segment)
          line = segments_from_error.first.line
          if line =~ Regexp.new("#{RecipeCache}([^/]+)/recipes/([^:]+):([0-9]+):in `from_file'") #TODO: is this still a 0.10 error form?
            cookbook = $1
            recipe_filename = $2
            @error_line_num = $3.to_i 
            @error_file_ref = ChefFileRef.recipe(cookbook,recipe_filename)
            @error_detail = segments_from_error.first.aux_data.first
          elsif line =~ /\((.+)::(.+) line ([0-9]+)\) has had an error/
            cookbook = $1
            recipe_filename = "#{$2}.rb"
            @error_line_num = $3.to_i 
            @error_file_ref = ChefFileRef.recipe(cookbook,recipe_filename)
            if segments_from_error[2] and segments_from_error[2].line =~ /INFO: error: (.+$)/
              @error_detail = $1
            end
          end
        end
      end

      class ErrorMissingRecipe < ErrorChefLog 
        def self.isa?(segments_from_error)
          return nil unless segments_from_error.size > 1
          line = segments_from_error[1].line
          line =~ /ArgumentError: Cannot find a recipe matching/
        end
       private
        def parse!(segments_from_error,prev_segment)
          line = segments_from_error[1].line
          if line =~ /ArgumentError: (.+$)/
            @error_detail = $1
          end
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
        def ret_file_asset(model_handle)
          file_asset_path = ret_file_asset_path()
          return nil unless file_asset_path and self[:cookbook]
          sp_hash = {
            :filter => [:eq, :path, file_asset_path],
            :cols => [:id,:path,:implementation_info]
          }
          file_asset_mh = model_handle.createMH(:file_asset)
          Model.get_objects_from_sp_hash(file_asset_mh,sp_hash).find{|x|x[:implementation][:repo] == self[:cookbook]}
        end
       private
        def ret_file_asset_path()
          return nil unless self[:file_name]
          case self[:type]
           when :template
            #TODO: stub; since does not handle case where multiple versions
            "templates/default/#{self[:file_name]}"
           when :recipe
            "recipes/#{self[:file_name]}"
          end
        end
      end

      #order makes a differnce for parsing
      PossibleErrors = [ErrorTemplate,ErrorRecipe,ErrorMissingRecipe,ErrorService,ErrorGeneric]
    end
  end
end
