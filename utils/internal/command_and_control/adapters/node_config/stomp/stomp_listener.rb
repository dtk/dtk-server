module DTK
  module StompListener
    include EM::Protocols::Stomp

    def connection_completed
      connect :login => R8::Config[:mcollective][:username], :passcode => R8::Config[:mcollective][:password]
      Log.debug "Stomp Client, connection completed!"
    end

    def receive_msg msg
      if "CONNECTED".eql?(msg.command)
        # success connecting to stomp
        subscribe(R8::Config[:arbiter][:reply_topic])
        Log.debug "Connected to STOMP and subscribed to topic '#{R8::Config[:arbiter][:reply_topic]}'"
      elsif "ERROR".eql?(msg.command)
        # error connecting to stomp
        Log.error("Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ...", nil)
        raise "Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ..."
      else
        # decode message
        Log.debug "Decoding message"
        original_msg = decode(msg.body)
        msg_request_id = original_msg[:body][:request_id]

        # making sure that timeout threads do not run overtime
        CommandAndControlAdapter::StompMultiplexer.process_response(original_msg, msg_request_id)

        # discard message if not the one requested
        unless CommandAndControlAdapter::StompMultiplexer.callback_registry[msg_request_id]
          Log.info("Stomp message received with ID '#{msg_request_id}' is not for this tenant, and it is being ignored!")
        else
          CommandAndControlAdapter::StompMultiplexer.callback_registry[msg_request_id].process_msg(original_msg, msg_request_id)
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