require 'rubygems'
require 'mcollective'
require 'eventmachine'
require 'pp'
require 'mcollective'

#monkey patch additions
module MCollective
  class Client
    def r8_set_context()
      @connection.set_decode_context(self)
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

    def r8_sendreq(msg, agent, filter = {})
      target = Util.make_target(agent, :command, collective)

      reqid = Digest::MD5.hexdigest("#{@config.identity}-#{Time.now.to_f.to_s}-#{target}")

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
BlankFilter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
Options = {
        :disctimeout=>3,
        :config=>"/root/R8Server/utils/internal/command_and_control/adapters/node_config/mcollective/client.cfg",
        :filter=> BlankFilter,
        :timeout=>120
}

EM.run do
  include MCollective::RPC
  rpc_client = rpcclient("discovery",:options => Options)
  rpc_client.client.r8_set_context()

  rpc_client.client.r8_sendreq("ping","discovery")
  rpc_client.client.r8_sendreq("ping","discovery")
end
