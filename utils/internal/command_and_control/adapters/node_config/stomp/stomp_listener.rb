#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
module DTK
  module StompListener
    include EM::Protocols::Stomp

    NUMBER_OF_RETRIES = 5

    def connection_completed
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

    def receive_msg(msg)
      case msg.command
      when 'CONNECTED'
        # success connecting to stomp
        subscribe(R8::Config[:arbiter][:queue])
        @stomp_rdy = true
        Log.debug "Connected to STOMP and subscribed to queue '#{R8::Config[:arbiter][:queue]}'"
      when 'ERROR'
        Log.error("Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ...", nil)
        @stomp_rdy = true
        raise "Not able to connect to STOMP, reason: #{msg.header['message']}. Stopping listener now ..."
      else
        decoded_message = 
          begin
            decode(msg.body)
          rescue Exception => e
            Log.fatal("Error decrypting STOMP message, will have to ignore this message. Error: #{e.message}")
            nil
          end
        process_decoded_message(decoded_message) if decoded_message
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

      begin
        encoded_message = encode(message)
      rescue Exception => ex
        Log.fatal("Error encrypting STOMP message, will have to ignore this message. Error: #{ex.message}")
        return
      end

      if defined?(PhusionPassenger)
        @backup_client.publish(R8::Config[:arbiter][:topic], encoded_message)
      else
        send(R8::Config[:arbiter][:topic], encoded_message)
      end
    end

    private

    def process_decoded_message(message)
      request_id   = message[:requestid]
      pbuilder_id  = message[:pbuilderid]
      is_heartbeat = message[:heartbeat]
      # note pong messages are also heartbeat messages
      is_pong      = message[:pong] # TODO: do we still need is_pong
      
      Log.debug_pp ['Received STOMP message', [:requestid, :pbuilderid, :heartbeat, :pong].inject({}) { |h, k| h.merge(k => message[k]) }]

      AgentInfo.process_received_heartbeat_message(pbuilder_id) if is_heartbeat

      if request_id 
        if multiplexer.callbacks_list[request_id]
          multiplexer.process_response(message, request_id)
        else
          Log.info("Stomp message received with ID '#{request_id}' is not for this tenant, and it is being ignored!") unless is_heartbeat
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

    def multiplexer
      CommandAndControlAdapter::StompMultiplexer
    end

  end
end
