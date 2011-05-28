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

client = MCollective::Client.new(options[:config])
client.options = options

#monkey patch
class MCollective::Client
  attr_reader :connection
end

#client.connection.subscribe("/topic/mcollective.discovery.reply")

args = ["ping",
        "discovery",
        {"identity"=>[], "fact"=>[], "agent"=>[], "cf_class"=>[]}]
reqid = client.sendreq(*args)
#msg = client.receive(reqid)
i = 0
until i > 10
  msg = client.receive
  #msg = client.connection.receive
  pp msg
  i += 1
end

