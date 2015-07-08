require File.expand_path('msg_bus_message', File.dirname(__FILE__))
module XYZ
  # This is the class that the MessageProcessors pass back they get marshalled to and from json
  class ProcessorMsg
    attr_reader :msg_type,:msg_content,:target_object_id
    def initialize(hash)
      unless (illegal_keys = hash.keys - [:msg_type,:msg_content,:target_object_id]).empty?
        raise Error.new("illegal key(s) (#{illegal_keys.join(", ")}) in ProcessorMsg.new")
      end
      @msg_type = hash[:msg_type]
      @msg_content = hash[:msg_content] || {}
      @target_object_id = hash[:target_object_id]
    end
    # TBD: factory in case we want to have subclasses for diffeernt msg types 
    def self.create(hash)
      ProcessorMsg.new(hash)
    end    
    def marshal_to_message_bus_msg
      hash = {msg_type: @msg_type, msg_content: @msg_content}
      hash.merge!({target_object_id: @target_object_id}) if @target_object_id
      MessageBusMsgOut.new(hash)
    end

    def topic
      type = ret_obj_type_assoc_with_msg_type(@msg_type)
      MessageBusMsgOut.topic(type)
    end

    def key
      raise Error.new("missing target_object_id") if @target_object_id.nil?
      type = ret_obj_type_assoc_with_msg_type(@msg_type)
      MessageBusMsgOut.key(@target_object_id,type)
    end

    private

    def ret_obj_type_assoc_with_msg_type(msg_type)
      case msg_type
        when :propagate_asserted_value,:propagated_value,:asserted_value
          :attribute
        when :execute_on_node
          :node
        else
	  raise Error.new("unexpected msg_type: #{msg_type}")
      end
    end
  end
end