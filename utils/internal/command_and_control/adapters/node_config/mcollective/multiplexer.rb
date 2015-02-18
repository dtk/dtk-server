require 'singleton'
require File.expand_path('../../../protocol_multiplexer', File.dirname(__FILE__))
module DTK
  module CommandAndControlAdapter; class Mcollective
    class Multiplexer < ProtocolMultiplexer
      include Singleton
      def self.create(mcollective_client)
        instance.set(mcollective_client)
      end

      def set(mcollective_client)
        @mcollective_client = mcollective_client
        @mcollective_client.r8_set_context(self)
        super(@mcollective_client)
      end

      def new_request(agent,action, data)
        @mcollective_client.r8_new_request(agent,action, data)
      end

      def sendreq_with_callback(msg,agent,context_with_callbacks,filter={})
        trigger = {
          :generate_request_id => proc do |client|
            client.r8_generate_request_id(msg,agent,filter)
          end,
          :send_message => proc do |client,reqid|
            client.r8_sendreq_give_reqid(reqid,msg,agent,filter)
          end
        }
        process_request(trigger,context_with_callbacks)
      end
    end
  end; end
end
