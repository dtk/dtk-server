module DTK
  module StompListener
    include EM::Protocols::Stomp

    NUMBER_OF_RETRIES = 5
    IDLE_RECONNECT_TIME = 300

    def connection_completed
      @message_registry = {}
      @sync_lock = Mutex.new
      # there is an issue with stomp connection, which results in ERROR thrown first time when connecting. This is something that can be ignore
      # it looks like issue with EM stomp client since it does not effect functionaliy. After first error all seems to be working fine.
      @stomp_rdy = false
      Log.info("Establishing connection to STOMP server with credentials #{R8::Config[:stomp][:username]} / #{safe_print_stomp_password} ...")
      connect :login => R8::Config[:stomp][:username], :passcode => R8::Config[:stomp][:password]

      if defined?(PhusionPassenger)
        Log.info("Created second STOMP client due to Passenger bug, this client will be used to sent AMQ messages.")
        create_second_client
      end

    end

    def create_second_client
      configuration = {
        stomp_username: R8::Config[:stomp][:username],
        stomp_password: R8::Config[:stomp][:password],
        stomp_host: R8::Config[:stomp][:host],
        stomp_port: R8::Config[:stomp][:port].to_i
      }
      @backup_client = ::Stomp::Client.new(:hosts => [{:login => configuration[:stomp_username], :passcode => configuration[:stomp_password], :host => configuration[:stomp_host], :port => configuration[:stomp_port], :ssl => false}])
    end

    def unbind
      # called when connection completed
      super
    end

    def receive_msg msg
      if "CONNECTED".eql?(msg.command)
        # success connecting to stomp
        subscribe(R8::Config[:arbiter][:queue])
        @stomp_rdy = true
        Log.debug "Connected to STOMP and subscribed to queue '#{R8::Config[:arbiter][:queue]}'"
      elsif "ERROR".eql?(msg.command)
        Log.error("Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ...", nil)
         @stomp_rdy = true
        raise "Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ..."
      else
        original_msg = decode(msg.body)

        msg_request_id = original_msg[:requestid]
        pbuilder_id    = original_msg[:pbuilderid]
        is_heartbeat   = original_msg[:heartbeat]

        deregister_incoming(msg_request_id)

        # decode message
        Log.debug "Recived message from STOMP, message id '#{msg_request_id}' from pbuilderid '#{pbuilder_id}' ..."

        # we map our heartbeat calls to requst IDs
        if is_heartbeat
          msg_request_id = CommandAndControlAdapter::StompMultiplexer.heartbeat_registry_entry(pbuilder_id)
          if msg_request_id
            Log.debug("Heartbeat message recived, and mapped from '#{pbuilder_id}' to request ID '#{msg_request_id}'")
          else
            Log.debug("Heartbeat message recived from '#{pbuilder_id}', dropping message since it could not be resolved to this tenant")
            return
          end
        end

        callbacks = CommandAndControlAdapter::StompMultiplexer.callback_registry[msg_request_id]

        unless callbacks
          # discard message if not the one requested
          Log.info("Stomp message received with ID '#{msg_request_id}' is not for this tenant, and it is being ignored!")
          return
        end

        # making sure that timeout threads do not run overtime
        CommandAndControlAdapter::StompMultiplexer.process_response(original_msg, msg_request_id)
      end
    end

    def publish(message)
      tries = NUMBER_OF_RETRIES

      # we can timeout here, in case stomp not ready
      while !@stomp_rdy
        if tries == 0
          raise Error, "We are not able to connect to STOMP server, aborting action!"
        end

        sleep(1)
        tries -= 1
      end
      ##
      # Hack, to have ti working on passenger, since send was not working on passenger and we cannot figure out why
      #
      register_outgoing(message[:request_id])

      if defined?(PhusionPassenger)
        @backup_client.publish(R8::Config[:arbiter][:topic], encode(message))
      else
        send(R8::Config[:arbiter][:topic], encode(message))
      end

      R8EM.add_timer(IDLE_RECONNECT_TIME) { check_hanging_messages() }
    end

  private

    def register_outgoing(request_id)
      return unless request_id
      @message_registry[request_id] = Time.now
    end

    def deregister_incoming(request_id)
      return unless request_id
      @message_registry.delete(request_id)
    end

    def check_hanging_messages
      return if @message_registry.size == 0

      @sync_lock.synchronize do
        current_time = Time.now

        # return 2-element array with key and value
        max_time = @message_registry.max_by { |k, v| v }

        max_wait_time = current_time - max_time.last

        if max_wait_time > (IDLE_RECONNECT_TIME - 10)
          # to avoid repeatition we set max time
          @message_registry[max_time.first] = Time.now

          Log.info("STOMP listener has not received response for #{(IDLE_RECONNECT_TIME-10)} seconds, we are restarting connection")
          reconnect(R8::Config[:stomp][:host], R8::Config[:stomp][:port].to_i)
          Log.info("STOMP connection has been restarted, waiting for a queue")
        else
          Log.debug("No STOMP pending messages that are waiting more than '#{(IDLE_RECONNECT_TIME - 10)}'")
        end
      end
    end

    def safe_print_stomp_password
      (R8::Config[:stomp][:password] || '').gsub(/./,'*')
    end

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
