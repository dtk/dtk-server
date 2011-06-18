#!/usr/bin/env ruby
require 'rubygems'
require 'digest/md5'
require 'eventmachine'
require 'pp'

module XYZ
  module MCollectiveMockClients
    include EM::Protocols::Stomp
    Msg_types = {
      :get_log_fragment => [:command],
      :discovery => [:command],
      :chef_solo => [:command],
      :puppet_apply => [:command],
    }
   def connection_completed
     connect :login => 'mcollective', :passcode => 'marionette'
   end

   def receive_msg msg
     if msg.command == "CONNECTED"
       Msg_types.each do |a,dirs|
         dirs =  [:command,:reply] if dirs.empty?
         dirs.each do |dir|
           subscribe("/topic/mcollective.#{a}.#{dir}")
         end
       end
     else
       decoded_msg = Marshal.load(msg.body)#Security.decodemsg(msg.body)
       decoded_msg[:body] = Marshal.load(decoded_msg[:body])
       pp ['got a message', decoded_msg]
       respond_to(decoded_msg)
      end
    end

    def respond_to(msg)
      if msg[:msgtarget] =~ /discovery.command$/
        respond_to__discovery(msg)
      else
        pp ['got a message', msg]
      end
    end
    def respond_to__discovery(msg)
      reply,target = encodereply("discovery","pong",msg[:requestid])
      send(target, reply)
    end

    def encodereply(agent, msg, requestid)
      sender_id = "foo"
      serialized  = Marshal.dump(msg)
      digest = Digest::MD5.hexdigest(serialized.to_s + "unset")
      target = "/topic/mcollective.#{agent}.reply"
      req = {
        :senderid => sender_id,
        :requestid => requestid,
        :senderagent => agent,
        :msgtarget => target,
        :msgtime => Time.now.to_i,
        :body => serialized
      }
      req[:hash] = digest
      reply = Marshal.dump(req)
      [reply,target]
    end
    
  end
end

EM.run{
  EM.connect 'localhost', 6163, XYZ::MCollectiveMockClients
}

