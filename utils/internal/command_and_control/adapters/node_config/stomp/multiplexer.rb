require 'singleton'
require 'openssl'

require File.expand_path('../../../protocol_multiplexer', File.dirname(__FILE__))
require File.expand_path('../../../../ssh_cipher', File.dirname(__FILE__))

module DTK
  module CommandAndControlAdapter

    class StompMultiplexer < ProtocolMultiplexer
      include Singleton


      @@listener_active = false
      @@callback_registry = {}

      def self.create(stomp_client)
        instance.set(stomp_client)
      end

      def set(stomp_client)
        @stomp_client = stomp_client
        super(stomp_client)
      end

      def create_message(uuid, msg, agent, pbuilderid)
        msg.merge({
          request_id: uuid,
          pbuilderid: pbuilderid
        })
      end

      def register_with_listener(request_id, callbacks)
        @@callback_registry[request_id] = callbacks
        Log.info("Stomp message ID '#{request_id}' has been registered! Waiting for callback.")
      end

      def self.process_response(msg, request_id)
        instance.process_response(msg, request_id)
      end

      def self.callback_registry
        @@callback_registry
      end

      def sendreq_with_callback(msg, agent, context_with_callbacks, filter = {})
        trigger = {
          generate_request_id: proc do |client|
            ::MCollective::SSL.uuid.gsub("-", "")
          end,
          send_message: proc do |client, reqid|
            message = create_message(reqid, msg, agent, filter['fact'].first[:value])
            client.publish(message)

            register_with_listener(reqid, Callbacks.create(context_with_callbacks[:callbacks]))
          end
        }

        process_request(trigger, context_with_callbacks)
      end
    end
  end
end
