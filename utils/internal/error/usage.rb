module DTK
  class ErrorUsage < Error
    class DanglingComponentRefs < self
      def initialize(cmp_ref_info_list)
        super(err_msg(cmp_ref_info_list))
        #each element can be a component ref object or a hash
        @cmp_ref_info_list = cmp_ref_info_list 
      end

      attr_reader :cmp_ref_info_list

      class Aggregate 
        def initialize(opts={})
          @cmp_ref_info_list = Array.new
          @error_cleanup = opts[:error_cleanup]
        end

        def aggregate_errors!(&block)
          begin
            yield
           rescue DanglingComponentRefs => e
            @cmp_ref_info_list = ret_unique_union(@cmp_ref_info_list,e.cmp_ref_info_list)
           rescue Exception => e
            @error_cleanup.call() if @error_cleanup
            raise e
          end
        end

        def raise_error?()
          unless @cmp_ref_info_list.empty?()
            @error_cleanup.call() if @error_cleanup
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

