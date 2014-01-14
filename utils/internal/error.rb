r8_nested_require('error','rest_error')
module DTK
  class Error < NameError
    r8_nested_require('error','usage')

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

#TODO: deprecating
#  class R8ParseError < Error
#    def initialize(msg,calling_obj=nil)
#      msg = (calling_obj ? "#{msg} in class #{calling_obj.class.to_s}" : msg)
#      super(msg)
#    end
#  end

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
