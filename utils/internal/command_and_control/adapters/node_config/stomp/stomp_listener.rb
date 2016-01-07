module DTK
  module StompListener
    include EM::Protocols::Stomp

    NUMBER_OF_RETRIES = 5

    def connection_completed
      # there is an issue with stomp connection, which results in ERROR thrown first time when connecting. This is something that can be ignore
      # it looks like issue with EM stomp client since it does not effect functionaliy. After first error all seems to be working fine.
      @stomp_rdy = false
      Log.info("Establishing connection to STOMP server with credentials #{R8::Config[:mcollective][:username]} / #{R8::Config[:mcollective][:password]} ...")
      connect :login => R8::Config[:mcollective][:username], :passcode => R8::Config[:mcollective][:password]

      if defined?(PhusionPassenger)
        Log.info("Created second STOMP client due to Passenger bug, this client will be used to sent AMQ messages.")
        create_second_client
      end

    end

    def create_second_client
      configuration = {
        stomp_username: R8::Config[:mcollective][:username],
        stomp_password: R8::Config[:mcollective][:password],
        stomp_host: R8::Config[:server_public_dns],
        stomp_port: R8::Config[:mcollective][:port].to_i
      }
      @backup_client = ::Stomp::Client.new(:hosts => [{:login => configuration[:stomp_username], :passcode => configuration[:stomp_password], :host => configuration[:stomp_host], :port => configuration[:stomp_port], :ssl => false}])
    end

    def receive_msg msg
      if "CONNECTED".eql?(msg.command)
        # success connecting to stomp
        subscribe(R8::Config[:arbiter][:reply_topic])
        @stomp_rdy = true
        Log.debug "Connected to STOMP and subscribed to topic '#{R8::Config[:arbiter][:reply_topic]}'"
      elsif "ERROR".eql?(msg.command)
        Log.error("Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ...", nil)
         @stomp_rdy = true
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
      sleep(1) while !@stomp_rdy
      ##
      # Hack, to have ti working on passenger, since send was not working on passenger and we cannot figure out why
      #
      if defined?(PhusionPassenger)
        @backup_client.publish(R8::Config[:arbiter][:topic], encode(message))
      else
        send(R8::Config[:arbiter][:topic], encode(message))
      end
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