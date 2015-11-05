require 'singleton'

require File.expand_path('../../../protocol_multiplexer', File.dirname(__FILE__))

module DTK
  module CommandAndControlAdapter

    class StompMultiplexer < ProtocolMultiplexer
      include Singleton

      @@listening_thread = nil
      @@callback_registry = {}

      def self.create(stomp_client)
        instance.set(stomp_client)
      end

      def set(stomp_client)
        @stomp_client = stomp_client
        super(stomp_client)
      end

      def create_message(uuid, msg, agent)
        deliver_msg = msg.merge({
          request_id: uuid
        })

        Base64.encode64(deliver_msg.to_yaml)
      end

      # heart of the system
      def initialize_listener(request_id, callbacks)
        @@callback_registry[request_id] = callbacks

        @@listening_thread ||= Thread.new do
          @stomp_client.subscribe(R8::Config[:arbiter][:reply_topic]) do |msg|
            begin
              original_msg = decode64(msg.body)
              request_id = original_msg[:body][:request_id]
              @@callback_registry[request_id].process_msg(original_msg, request_id)
            rescue Exception => e
              ap "THREAD Exception #{e.message}"
            end
          end
          @stomp_client.join
        end
      end

      def sendreq_with_callback(msg, agent, context_with_callbacks, filter = {})
        request_id = ::MCollective::SSL.uuid.gsub("-", "")
        callbacks = Callbacks.create(context_with_callbacks[:callbacks])
        timeout = context_with_callbacks[:timeout] || DefaultTimeout
        expected_count = context_with_callbacks[:expected_count] || ExpectedCountDefault

        @stomp_client.publish(R8::Config[:arbiter][:topic], create_message(request_id, msg, agent))

        initialize_listener(request_id, callbacks)

        request_id
      end

    private

      def decode64(message)
        decoded_message = Base64.decode64(message)
        YAML.load(decoded_message)
      end

    end
  end
end
