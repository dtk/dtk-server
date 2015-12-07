require 'singleton'
require 'openssl'

require File.expand_path('../../../protocol_multiplexer', File.dirname(__FILE__))
require File.expand_path('../../../../ssh_cipher', File.dirname(__FILE__))

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

      def create_message(uuid, msg, agent, pbuilderid)
        msg.merge({
          request_id: uuid,
          pbuilderid: pbuilderid
        })
      end

      # heart of the system
      def initialize_listener(request_id, callbacks)
        @@callback_registry[request_id] = callbacks

        @@listening_thread ||= Thread.new do
          @stomp_client.subscribe(R8::Config[:arbiter][:reply_topic]) do |msg|
            begin
              original_msg = decode(msg.body)
              msg_request_id = original_msg[:body][:request_id]

              # discard message if not the one requested
              unless @@callback_registry[msg_request_id]
                Log.info("Stomp message received with ID '#{msg_request_id}' is not for this tenant, and it is being ignored!")
              else
                @@callback_registry[msg_request_id].process_msg(original_msg, msg_request_id)
              end
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

        message = create_message(request_id, msg, agent, filter['fact'].first[:value])

        @stomp_client.publish(R8::Config[:arbiter][:topic], encode(message))

        initialize_listener(request_id, callbacks)

        request_id
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
end