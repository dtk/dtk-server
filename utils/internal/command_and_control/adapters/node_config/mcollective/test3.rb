#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require 'mcollective'
require 'poller'
require 'listener'
oparser = MCollective::Optionparser.new({:verbose => true})

options = oparser.parse{|parser, options|
    parser.define_head "Pings all hosts and report their names and some stats"
}

Sema = Mutex.new
def new_client()
  client = nil
  Sema.synchronize{client = MCollective::Client.new("/etc/mcollective/client.cfg")}
  client.connection.subscribe("/topic/mcollective.discovery.reply")
  client
end

#monkey patch
class MCollective::Client
  attr_reader :connection
end

def listen_loop(client=nil)
  client ||= new_client()
  count = 10
  (1..count).each do |i|
    msg = client.connection.receive
    pp [Thread.current,msg]
  end
end
#in this configuration of mc-ping is done get responses for each thread; need to figure out if enable below get 6 responses
#and makes no difference if in thread or not
client = client2 = nil
#client = new_client()
#client2 = new_client()
threads = Array.new
threads << Thread.new{listen_loop(client)}
threads << Thread.new{listen_loop(client2)}

#=begin
threads << Thread.new do
args = ["ping",
        "discovery",
        {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}]
reqid = new_client().sendreq(*args)
end
#=end
threads.each{|t|t.join}

