r8_require_common_lib('errors')
module DTK
  class Error ##TODO: cleanup; DTK::Error is coming from /home/dtk18/dtk-common/lib/errors/errors.rb  
    r8_nested_require('error','rest_error')
    r8_nested_require('error','usage')
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
