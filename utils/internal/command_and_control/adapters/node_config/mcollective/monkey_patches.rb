require 'mcollective'
######## Monkey patches for version 1.3.2 
module MCollective
  class Discovery
    class Mc
      def self.discover(filter, timeout, limit, client)
        count = 1
        begin
          hosts = []
          Timeout.timeout(timeout) do
            reqid = client.sendreq("ping", "discovery", filter)
            Log.debug("Waiting #{timeout} seconds for discovery replies to request #{reqid}")

            loop do
              count += 1
              reply = client.receive(reqid)
              Log.debug("Got discovery reply from #{reply.payload[:senderid]}")
              hosts << reply.payload[:senderid]

              # return hosts if limit > 0 && hosts.size == limit
              return reply if limit > 0 && hosts.size == limit
            end
          end
        rescue Timeout::Error => e
          # for some reason when calling client.receive(reqid) for the first time it times out
          # so calling 3 times just in case it does not return response after first time
          retry if count < 3
        rescue Exception => e
          raise
        ensure
          client.unsubscribe("discovery", :reply)
        end

        hosts
      end
    end
  end
  class Client
    def r8_set_context(multiplexer)
      @connection.set_context(decode_context: self,multiplexer: multiplexer)
    end

    # changed to specficall take an agent argument
    def r8_new_request(agent,action, data)
      callerid = @security.callerid
      {agent: agent,
        action: action,
        caller: callerid,
        data: data}
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

    def r8_sendreq_give_reqid(reqid,msg,agent,filter = {},&_block)
      # TODO: see if can put in block form that first generates request id then calss functions that need it
      # then does subscribe and send

      # TODO: rather than below see if can use
      # following
      # msg = create_request_message(msg,agent,filter)
      # msg.encode!
      # block.call(msg.create_reqid) if block
      # req = msg.payload

      target = make_target(agent, :request, collective)
      req = @security.encoderequest(@config.identity, msg, reqid, filter, agent, collective)
      topic = make_target(agent, :reply, collective)
      log_msg = "Sending request #{reqid} to topic #{target}"
      if id_if_set = ((filter["fact"]||[]).first||{})[:value]
        log_msg << " with filter on id: #{id_if_set}"
      end
      Log.debug(log_msg)
      @connection.subscribe_and_send(topic,target,req)
      reqid
    end

    private

    def make_target(agent, type, collective, target_node=nil)
      @connection.make_target(agent, type, collective, target_node)
    end

    def create_request_message(msg,agent,filter)
      type = :request #TODO: stub so can use direct types
      Message.new(msg,nil,agent: agent, filter: filter, collective: collective, type: type)
    end
  end
end

