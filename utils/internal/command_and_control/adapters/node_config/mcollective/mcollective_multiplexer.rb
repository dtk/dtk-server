require 'singleton'
require File.expand_path('../../../protocol_multiplexer', File.dirname(__FILE__))
module XYZ
  module CommandAndControlAdapter
    class MCollectiveMultiplexer < ProtocolMultiplexer
      include Singleton
      include MCollective::RPC
      def initialize()
        #TODO: directly create MCollective::Client rather than rpcclient
        @mcollective_client = rpcclient("discovery",:options => Options).client
        @mcollective_client.r8_set_context(self)
        super(@mcollective_client)
      end
      BlankFilter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
      Options = {
        :disctimeout=>3, #TODO: no longer using; remove
        :config=>File.expand_path("client.cfg", File.dirname(__FILE__)),
        :filter=> BlankFilter,
        :timeout=>120
      }

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
  end
end

#TODO: unify these with the other monkey patches
####monkey patches
module MCollective
  class Client
    def r8_set_context(multiplexer)
      @connection.set_context(:decode_context => self,:multiplexer => multiplexer)
    end

    #changed to specficall take an agent argument
    def r8_new_request(agent,action, data)
      callerid = @security.callerid
      {:agent  => agent,
        :action => action,
        :caller => callerid,
        :data   => data}
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
      target = Util.make_target(agent, :command, collective)
      reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")
    end

    def r8_sendreq_give_reqid(reqid,msg,agent,filter = {})
      target = Util.make_target(agent, :command, collective)
      # Security plugins now accept an agent and collective, ones written for <= 1.1.4 dont
      # but we still want to support them, try to call them in a compatible way if they
      # dont support the new arguments
      begin
        req = @security.encoderequest(@config.identity, target, msg, reqid, filter, agent, collective)
      rescue ArgumentError
        req = @security.encoderequest(@config.identity, target, msg, reqid, filter)
      end

      topic = Util.make_target(agent, :reply, collective)
      Log.debug("Sending request #{reqid} to #{target}")
      @connection.subscribe_and_send(topic,target,req)
      reqid
    end
  end
end

