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
def new_client(opts={})
  client = nil
  Sema.synchronize{client = MCollective::Client.new("/etc/mcollective/client.cfg")}
  client.connection.subscribe("/topic/mcollective.discovery.reply") unless opts[:no_subscribe]
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
#looks like what happens is a function of having clients in different threads and which ones do a  subscribe
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
reqid = new_client(:no_subscribe => true).sendreq(*args)
end
#=end
threads.each{|t|t.join}

