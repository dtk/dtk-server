module XYZ
  class Error < NameError
    def self.top_error_in_hash()
      {:error => :Error}
    end
    def initialize(msg="",name=nil)
      super(msg,name)
      Log.info(to_s)
    end
    def to_hash()
      if to_s == "" 
        Error.top_error_in_hash()
      elsif name.nil?
        {:error => {:Error => {:msg => to_s}}}
      else
        {:error => {name.to_sym => {:msg => to_s}}}
      end
    end
  end
  class ErrorConstraintViolations < Error
    def initialize(violations)
       super(msg(violations),:ConstraintViolations)
    end
   private
    def msg(violations)
      v_with_text = violations.compact
      if v_with_text.size < 2
        return "constraint violations"
      elsif v_with_text.size == 2
        return "constraint violations: #{v_with_text[1]}"
      end
      ret = "constraint violations: "
      ret << (v_with_text.first == :or ? "one of " : "")
      ret << "(#{v_with_text[1..v_with_text.size-1].join(",")})"
    end
  end

  class ErrorNotImplemented < Error
    def initialize(msg="NotImplemented error")
      super("in #{this_parent_parent_method}: #{msg}",:NotImplemented)
    end
  end

  class ErrorNotFound < Error
    attr_reader :obj_type,:obj_value
    def initialize(obj_type=nil,obj_value=nil)
      @obj_type = obj_type
      @obj_value = obj_value
    end
    def to_s()
      if obj_type.nil?
        "NotFound error:" 
      elsif obj_value.nil?
        "NotFound error: type = #{@obj_type.to_s}"
      else
        "NotFound error: #{@obj_type.to_s} = #{@obj_value.to_s}"
      end
    end
    def to_hash()
      if obj_type.nil?
         {:error => :NotFound}
      elsif obj_value.nil?
        {:error => {:NotFound => {:type => @obj_type}}}
      else
        {:error => {:NotFound => {:type => @obj_type, :value => @obj_value}}}
      end
    end
  end
  class ErrorUserInputNeeded < Error
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
  class ErrorAMQP < Error
    def to_s()
      "AMQP error"
    end
  end
  class ErrorAMQPQueueDoesNotExist < ErrorAMQP
    attr_reader :queue_name
    def initialize(queue_name)
      @queue_name = queue_name
    end
    def to_s()
      "queue #{queue_name} does not exist"
    end
  end
end
