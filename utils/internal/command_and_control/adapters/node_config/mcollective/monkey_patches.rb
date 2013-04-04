require 'mcollective'
######## Monkey patches for version 1.3.2 
module MCollective
  class Client
    def r8_set_context(multiplexer)
      @connection.set_context(:decode_context => self,:multiplexer => multiplexer)
    end

    #changed to specficall take an agent argument
    def r8_new_request(agent,action, data)
      callerid = @security.callerid
      {:agent  => agent,
        :action => action,
        :caller => callerid,
        :data   => data}
    end

    def r8_decode_receive(msg)
      begin
        msg = @security.decodemsg(msg)
        msg[:senderid] = Digest::MD5.hexdigest(msg[:senderid]) if ENV.include?("MCOLLECTIVE_ANON")
      rescue Exception => e
        Log.debug("decoding error")
        msg = nil
      end
      msg
    end

    def r8_generate_request_id(msg, agent, filter = {})
      create_request_message(msg,agent,filter).create_reqid
    end

    def r8_sendreq_give_reqid(reqid,msg,agent,filter = {},&block)
      #TODO: see if can put in block form that first generates request id then calss functions that need it
      #then does subscribe and send

      #TODO: rather than below see if can use
      #following
      #msg = create_request_message(msg,agent,filter)
      #msg.encode!
      #block.call(msg.create_reqid) if block
      #req = msg.payload

      target = make_target(agent, :request, collective)
      req = @security.encoderequest(@config.identity, msg, reqid, filter, agent, collective)
      topic = make_target(agent, :reply, collective)
      Log.debug("Sending request #{reqid} to #{target}")
      @connection.subscribe_and_send(topic,target,req)
      reqid
    end

    private
    def make_target(agent, type, collective, target_node=nil)
      @connection.make_target(agent, type, collective, target_node)
    end
    def create_request_message(msg,agent,filter)
      type = :request #TODO: stub so can use direct types
      Message.new(msg,nil,:agent => agent, :filter => filter, :collective => collective, :type => type)
    end
  end
end

