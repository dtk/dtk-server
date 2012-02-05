require 'mcollective'
######## Monkey patches for version 1.2 
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
      target = make_target(agent, :request, collective)
      reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")
    end

    def r8_sendreq_give_reqid(reqid,msg,agent,filter = {})
      target = make_target(agent, :request, collective)
#1.3.2 CHANGE        req = @security.encoderequest(@config.identity, target, msg, reqid, filter, agent, collective)
      req = @security.encoderequest(@config.identity, msg, reqid, filter, agent, collective)

      topic = make_target(agent, :reply, collective)
      Log.debug("Sending request #{reqid} to #{target}")
      @connection.subscribe_and_send(topic,target,req)
      reqid
    end

#1.3.2 CHANGE [added new ffn taht copied from stomp conector plugin
    #TODO: this shoudl instead be call to pluggin
    def make_target(agent, type, collective, target_node=nil)
      raise("Unknown target type #{type}") unless [:directed, :broadcast, :reply, :request, :direct_request].include?(type)
      raise("Unknown collective '#{collective}' known collectives are '#{@config.collectives.join ', '}'") unless @config.collectives.include?(collective)

      prefix = @config.topicprefix

      case type
      when :reply
        suffix = :reply
      when :broadcast
        suffix = :request
      when :request
        suffix = :command
      when :direct_request
        agent = nil
        prefix = @config.queueprefix
        suffix = Digest::MD5.hexdigest(target_node)
      when :directed
        agent = nil
        prefix = @config.queueprefix
        # use a md5 since hostnames might have illegal characters that
        # the middleware dont understand
        suffix = Digest::MD5.hexdigest(@config.identity)
      end

      ["#{prefix}#{collective}", agent, suffix].compact.join(@config.topicsep)
    end
  end
end

