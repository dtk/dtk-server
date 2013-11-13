module DTK
  class ErrorUsage < Error
    class DSLParsing < self
      def initialize(base_json_error,file_path=nil)
        super(err_msg(base_json_error,file_path))
      end
     private
      def err_msg(base_json_error,file_path=nil)
        file_ref = file_path && " in file (#{file_path})"
        # "JSON parsing error#{file_ref}: #{base_json_error}"
        "#{base_json_error}: #{file_path}"
      end

      class JSONParsing < self
      end

      class YAMLParsing < self
      end

      class BadNodeReference < self
      end

      class BadComponentReference < self
      end

      class BadServiceLink < self
        private 
        def err_msg(base_json_error, path=nil)
          "#{base_json_error} for '#{path}'."
        end
      end
    end


    class ReferencedComponentTemplates < self
      def initialize(aug_cmp_templates)
        super(err_msg(aug_cmp_templates))
        @aug_cmp_templates = aug_cmp_templates
      end
      private
      def err_msg(aug_cmp_templates)
        ident = "  "
        ref_errors = ident + aug_cmp_templates.map{|cmp_tmpl|msg_per_cmp_template(cmp_tmpl)}.flatten.join("\n#{ident}")
        size = aug_cmp_templates.size
        what = (size==1 ? "component template" : "component templates")
        is = (size==1 ? "is" : "are")
        "The following #{what} would be deleted, but #{is} referenced by existing assembly templates:\n#{ref_errors}"
      end
      def msg_per_cmp_template(cmp_tmpl)
        cmp_template = cmp_tmpl.display_name_print_form
        cmp_tmpl[:component_refs].map do |aug_cmp_ref|
          #TODO: aug_cmp_ref also has node and component ref fields that can be displayed
          assembly_template = Assembly::Template.pretty_print_name(aug_cmp_ref[:assembly_template])
          "Component Template (#{cmp_template}) is referenced by assembly template (#{assembly_template})"
        end
      end
    end

    class DanglingComponentRefs < self
      def initialize(cmp_ref_info_list)
        super(err_msg(cmp_ref_info_list))
        #each element can be a component ref object or a hash
        @cmp_ref_info_list = cmp_ref_info_list 
      end

      #
      # Returns list of missing modules with version
      #
      def missing_module_list()
        #forming hash and then getting its vals to remove dups in same <module,version,namepsace>
        module_hash = @cmp_ref_info_list.inject(Hash.new) do |h,r|
          module_name = r[:component_type].split('__').first
          remote_namespace = r[:remote_namespace]
          ndx = "#{module_name}---#{r[:version]}---#{remote_namespace}"
          info = {
            :name => module_name, 
            :version => r[:version]
          }
          info.merge!(:remote_namespace => remote_namespace) if remote_namespace
          h.merge!(ndx => info)
        end

        module_hash.values
      end

      attr_reader :cmp_ref_info_list

      class Aggregate 
        def initialize(opts={})
          @cmp_ref_info_list = Array.new
          @error_cleanup = opts[:error_cleanup]
        end

        def aggregate_errors!(ret_when_err=nil,&block)
          begin
            yield
           rescue DanglingComponentRefs => e
            @cmp_ref_info_list = ret_unique_union(@cmp_ref_info_list,e.cmp_ref_info_list)
            ret_when_err
           rescue Exception => e
            @error_cleanup.call() if @error_cleanup
            raise e
          end
        end

        def raise_error?(opts={})
          unless @cmp_ref_info_list.empty?()
            @error_cleanup.call() if @error_cleanup
            return DanglingComponentRefs.new(@cmp_ref_info_list) if opts[:do_not_raise]
            raise DanglingComponentRefs.new(@cmp_ref_info_list)
          end
        end
        
       private
        def ret_unique_union(cmp_refs1,cmp_refs2)
          ndx_ret = cmp_refs1.inject(Hash.new){|h,r|h.merge(ret_unique_union__ndx(r) => r)}
          cmp_refs2.inject(ndx_ret){|h,r|h.merge(ret_unique_union__ndx(r) => r)}.values
        end
        
        def ret_unique_union__ndx(cmp_ref_info)
          ret = cmp_ref_info[:component_type]
          if version = cmp_ref_info[:version]
            ret = "#{ret}(#{version})"
          end
          ret
        end

      end

     private
      def err_msg(cmp_ref_info_list)
        what = (cmp_ref_info_list.size==1 ? "component template" : "component templates")
        refs = cmp_ref_info_list.map{|cmp_ref_info|print_form(cmp_ref_info)}.compact.join(",")
        is = (cmp_ref_info_list.size==1 ? "is" : "are")
        does = (cmp_ref_info_list.size==1 ? "does" : "do")
        "The following #{what} (#{refs}) that #{is} referenced by assemblies in the service module #{does} not exist"
      end

      def print_form(cmp_ref_info)
        ret = ComponentRef.print_form(cmp_ref_info)
        if version = cmp_ref_info[:version]
          ret = "#{ret}(#{version})"
        end
        ret
      end

    end

    #TODO: make second argument be polymorphic to handle things like wrong type, wrong name
    class BadParamValue < self
      def initialize(param,enum_vals=nil)
        super(msg(param,enum_vals))
      end
     private
      def msg(param,enum_vals)
        msg = "Paramater '#{param}' has an illegal value"
        if enum_vals
          msg << "; most be one of (#{enum_vals.join(",")})"
        end
        msg
      end
    end

    class BadVersionValue < self
      def initialize(version_value)
        super(msg(version_value))
      end

      def msg(version_value)
        "Version has an illegal value '#{version_value}', format needed: '##.##.##'"
      end
    end
  end

  #TODO: nest these also under ErrorUsage
  class ErrorsUsage < ErrorUsage
    def initialize()
      @errors = Array.new
    end
    def <<(err)
      @errors << err
    end
    def empty?()
      @errors.empty?()
    end
    def to_s()
      if @errors.size == 1
        @errors.first.to_s()
      elsif @errors.size > 1
        "\n"+@errors.map{|err|err.to_s}.join("\n")
      else #no errors shoudl not be called 
        "No errors"
      end
    end
  end

  #TODO: move over to use nested classeslike above
  class ErrorIdInvalid <  ErrorUsage
    def initialize(id,object_type)
      super(msg(id,object_type))
    end
     def msg(id,object_type)
       "Illegal id (#{id}) for #{object_type}"
     end
  end
  class ErrorNameInvalid <  ErrorUsage
    def initialize(name,object_type)
      super(msg(name,object_type))
    end
     def msg(name,object_type)
       "Illegal name (#{name}) for #{object_type}"
     end
  end
  class ErrorNameAmbiguous <  ErrorUsage
    def initialize(name,matching_ids,object_type)
      super(msg(name,matching_ids,object_type))
    end
     def msg(name,matching_ids,object_type)
       "Ambiguous name (#{name}) for #{object_type} which matches ids: #{matching_ids.join(',')}"
     end
  end
  class ErrorNameDoesNotExist <  ErrorUsage
    def initialize(name,object_type,augment_string=nil)
      super(msg(name,object_type,augment_string))
      @name_param = name
      @object_type = object_type
    end

    def qualify(augment_string)
      self.class.new(@name_param,@object_type,augment_string)
    end

    def msg(name,object_type,augment_string)
      msg = "No object of type #{object_type} with name (#{name}) exists"
      if augment_string
        msg << " #{augment_string}"
      end
      msg
    end
  end

  class ErrorConstraintViolations < ErrorUsage
    def initialize(violations)
       super(msg(violations),:ConstraintViolations)
    end
   private
    def msg(violations)
      return ("constraint violation: " + violations) if violations.kind_of?(String)
      v_with_text = violations.compact
      if v_with_text.size < 2
        return "constraint violations"
      elsif v_with_text.size == 2
        return "constraint violations: #{v_with_text[1]}"
      end
      ret = "constraint violations: "
      ret << (v_with_text.first == :or ? "(atleast) one of " : "")
      ret << "(#{v_with_text[1..v_with_text.size-1].join(", ")})"
    end
  end

  class ErrorUserInputNeeded < ErrorUsage
    def initialize(needed_inputs)
      super()
      @needed_inputs = needed_inputs
    end
    def to_s()
      ret = "following inputs are needed:\n"
      @needed_inputs.each do |k,v|
        ret << "  #{k}: type=#{v[:type]}; description=#{v[:description]}\n"
      end
      ret
    end
  end
end

