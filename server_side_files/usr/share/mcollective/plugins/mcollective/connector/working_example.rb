require 'rubygems'
require 'mcollective'
require 'eventmachine'
require 'pp'
module MCollective
  module Connector
    class Base
      def self.inherited(klass)
        # added :single_instance => false
        PluginManager << {:type => "connector_plugin", :class => klass.to_s}
      end
    end
  end
end
require 'stomp_eventmachine'
def encoderequest(sender, target, msg, requestid, filter={}, target_agent=nil, target_collective=nil)
  serialized = Marshal.dump(msg)
  digest = makehash(serialized)

  req = create_request(requestid, target, filter, serialized, @initiated_by, target_agent, target_collective)
  req[:hash] = digest

  Marshal.dump(req)
end
def makehash(body)
  psk = "unset"
  Digest::MD5.hexdigest(body.to_s + psk)
end
def create_request(reqid, target, filter, msg, initiated_by, target_agent=nil, target_collective=nil)
  unless target_agent && target_collective
    parsed_target = MCollective::Util.parse_msgtarget(target)
    target_agent = parsed_target[:agent]
    target_collective = parsed_target[:collective]
  end

  {:body => msg,
    :senderid => "ip-10-117-78-231",
    :requestid => reqid,
    :msgtarget => target,
    :filter => filter,
    :collective => target_collective,
    :agent => target_agent,
    :callerid => "uid=0",
    :msgtime => Time.now.to_i}
end

EventMachine::run {
  connection = MCollective::PluginManager["connector_plugin"]
  connection.connect
#  connection.subscribe("/topic/mcollective.discovery.reply")
  agent = "discovery"
  collective = "mcollective"
  msg = "ping" 
  filter = {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}
#  target = MCollective::Util.make_target(agent, :command, collective)
  target = "/topic/mcollective.discovery.command"
  identity = "ip-10-117-78-231"
  reqid = Digest::MD5.hexdigest("#{identity}-#{Time.now.to_f.to_s}-#{target}")
  req = encoderequest(identity, target, msg, reqid, filter, agent, collective)
  connection.subscribe_and_send("/topic/mcollective.discovery.reply",target,req)
  connection.subscribe_and_send("/topic/mcollective.discovery.reply",target,req)
}

  
