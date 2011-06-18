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
      elsif msg[:msgtarget] =~ /chef_solo.command$/
        respond_to__chef_solo(msg)
      elsif msg[:msgtarget] =~ /puppet_apply.command$/
        respond_to__puppet_apply(msg)
      elsif msg[:msgtarget] =~ /get_log_fragment.command$/
        respond_to__get_log_fragment(msg)
      else
        pp ['cant treat msg', msg]
      end
    end
    def respond_to__discovery(msg)
      find_pbuilderids(msg).each do |pbuilderid|
        reply,target = encodereply(pbuilderid,"discovery","pong",msg[:requestid])
        send(target, reply)
      end
    end
    def respond_to__chef_solo(msg)
      find_pbuilderids(msg).each do |pbuilderid|
        response = {
          :statuscode=>0,
          :data=>
          {:status=>:succeeded,
            :node_name=>"domU-12-31-39-0B-F1-65.compute-1.internal"},
          :statusmsg=>"OK"
        }
        reply,target = encodereply(pbuilderid,"chef_solo",response,msg[:requestid])
        send(target, reply)
      end
    end
    def respond_to__get_log_fragment(msg)
      find_pbuilderids(msg).each do |pbuilderid|
        response = get_log_fragment_response(pbuilderid,msg)
        reply,target = encodereply(pbuilderid,"chef_solo",response,msg[:requestid])
        send(target, reply)
      end
    end

    def find_pbuilderids(msg)
      pb_fact = ((msg[:filter]||{})["fact"]||[]).find{|f|f[:fact]=="pbuilderid"}
      return Array.new unless pb_fact
      if pb_fact[:operator] == "=="
        [pb_fact[:value]]

      elsif pb_fact[:operator] == "=~"
        pbuilderids = Array.new
        pb_fact[:value].gsub(/[A-Za-z0-9-]+/){|m|pbuilderids << m} 
        pbuilderids
      else
        pp "got fact: #{pb_fact.inspect}"
          []
      end
    end

    def encodereply(pbuilderid,agent, msg, requestid)
      sender_id = pbuilderid
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

    def get_log_fragment_response(pbuilderid,msg)
      lines = get_log_fragment(msg)
      if lines.nil?
        error_msg = "Cannot find log fragment matching"
        error_response = {
          :status => :failed, 
          :error => {
            :formatted_exception => error_msg
          },
          :pbuilderid => pbuilderid
        }
        error_response
      else
        ok_response = {
          :status => :ok,
          :data => lines,
          :pbuilderid => pbuilderid
        }
        ok_response
      end
    end

    def get_log_fragment(msg)
      ret = String.new
      matching_file = nil
      matching_file = "/root/r8client/mock_logs/error1.log"
      begin
        f = File.open(matching_file)
        until f.eof
          ret << f.readline.chop
        end
      ensure
        f.close
      end
      ret
    end
  end
end

EM.run{
  EM.connect 'localhost', 6163, XYZ::MCollectiveMockClients
}

