module DTK
  module StompListener
    include EM::Protocols::Stomp

    NUMBER_OF_RETRIES = 5

    def connection_completed
      # there is an issue with stomp connection, which results in ERROR thrown first time when connecting. This is something that can be ignore
      # it looks like issue with EM stomp client since it does not effect functionaliy. After first error all seems to be working fine.
      @first_error_bypass ||= true
      Log.info("Establishing connection to STOMP server with credentials #{R8::Config[:mcollective][:username]} / #{R8::Config[:mcollective][:password]} ...")
      connect :login => R8::Config[:mcollective][:username], :passcode => R8::Config[:mcollective][:password]
    end

    def receive_msg msg
      if "CONNECTED".eql?(msg.command)
        # success connecting to stomp
        subscribe(R8::Config[:arbiter][:reply_topic])
        Log.debug "Connected to STOMP and subscribed to topic '#{R8::Config[:arbiter][:reply_topic]}'"
      elsif "ERROR".eql?(msg.command)
        #
        # There seems to be a bug here so for now we can ignore this
        #
        if @first_error_bypass
          @first_error_bypass = false
          return
        end

        # if @number_of_retries > 0
        #   CommandAndControlAdapter::Stomp.get_stomp_client(true)
        #   @number_of_retries = @number_of_retries - 1
        #   Log.info("Re-trying connection to STOMP, re-tries left: #{@number_of_retries} ")
        #   return
        # end

        Log.error("Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ...", nil)
        raise "Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ..."
      else
        # decode message
        Log.debug "Recived message from stomp, decoding ..."
        original_msg = decode(msg.body)

        msg_request_id = original_msg[:requestid]
        pbuilder_id    = original_msg[:pbuilderid]
        is_heartbeat   = original_msg[:heartbeat]

        # we map our heartbeat calls to requst IDs
        if is_heartbeat
          msg_request_id = CommandAndControlAdapter::StompMultiplexer.heartbeat_registry_entry(pbuilder_id)
          Log.debug("Heartbeat message recived, and mapped from '#{pbuilder_id}' to request ID '#{msg_request_id}'")
        end

        # making sure that timeout threads do not run overtime
        CommandAndControlAdapter::StompMultiplexer.process_response(original_msg, msg_request_id)

        callbacks = CommandAndControlAdapter::StompMultiplexer.callback_registry[msg_request_id]

        # discard message if not the one requested
        unless callbacks
          Log.info("Stomp message received with ID '#{msg_request_id}' is not for this tenant, and it is being ignored!")
        else
          callbacks.process_msg(original_msg, msg_request_id)
        end
      end
    end

    def publish(message)
      send(R8::Config[:arbiter][:topic], encode(message))
    end

  private

    def encode(message)
      encrypted_message, ekey, esecret = SSHCipher.encrypt_sensitive(message)
      Marshal.dump({ :payload => encrypted_message, :ekey => ekey, :esecret => esecret  })
    end

    def decode(message)
      encrypted_message = Marshal.load(message)

      decoded_message = SSHCipher.decrypt_sensitive(encrypted_message[:payload], encrypted_message[:ekey], encrypted_message[:esecret])
      decoded_message
    end

  end
end