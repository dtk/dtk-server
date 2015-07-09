module XYZ
  class MessageBusMsg
    def to_s
       @body.inspect
    end
    def self.unmarshall_from_wire(raw_msg)
      unmarshalled_hash = Aux::unmarshal_from_wire(raw_msg)
      MessageBusMsgIn.new(unmarshalled_hash)
    end
    def self.unmarshall_from_wire2(raw_header, raw_msg)
      unmarshalled_hash = Aux::unmarshal_from_wire(raw_msg)
      [MessageBusTransactionInfo.new(raw_header, unmarshalled_hash),
       MessageBusMsgIn.new(unmarshalled_hash)]
    end
  end
  class MessageBusMsgIn < MessageBusMsg
    # input so processor_msg can be formed
    def parse
      { msg_type: @body[:msg_type],
        msg_content: @body[:msg_content],
        target_object_id: @body[:target_object_id] }
    end

    private

    def initialize(unmarshalled_hash)
      @body = unmarshalled_hash[:body]
    end
  end

  class MessageBusMsgOut < MessageBusMsg
    def initialize(body)
      @body = body
    end

    # return raw_body,raw_publish_opts
    def marshal_to_wire(publish_opts)
      hash_body = { body: @body }
      raw_publish_opts = {}
      publish_opts.each do |k, v|
        if MessageBusTransactionInfo::In_amqp_header.include?(k)
          raw_publish_opts[k] = v
        else
          hash_body[k] = v
        end
      end
      [Aux::marshal_to_wire(hash_body), raw_publish_opts]
    end

    # type can be :attribute or :node
    def self.topic(type)
      case type
        when :attribute
          'default'
        when :node
          'node'
        else
         fail Error.new("unexpected type: #{type}")
      end
    end
    def self.key(target_object_id, type)
      fail Error.new("unexpected type: #{type}") unless [:attribute, :node].include?(type)
      fail Error.new('missing target_object_id') if target_object_id.nil?
      target_object_id.to_s
    end
  end

  class MessageBusTransactionInfo < HashObject
    def initialize(raw_header, unmarshalled_hash)
      super({})
      self[:reply_to] = raw_header.properties[:reply_to] if raw_header.properties[:reply_to]
      self[:message_id] = raw_header.properties[:message_id] if raw_header.properties[:message_id]
      self[:task] = unmarshalled_hash[:task] if unmarshalled_hash[:task]
      self[:create_task] = unmarshalled_hash[:create_task] if unmarshalled_hash[:create_task]
      # TBD: used for testing    self[:from] = unmarshalled_hash[:from] if unmarshalled_hash[:from]
    end
    In_amqp_header = [:key, :reply_to, :message_id]
  end
end
