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
include XYZ::CommandAndControl
listener = McollectiveListener.new(client)

#monkey patch
class MCollective::Client
  attr_reader :connection
end

threads = Array.new
threads << Thread.new do
  i = 0
  until i > 10
#    msg = client.receive
    msg = listener.process_event()
    pp msg
    i += 1
  end
end

poller = McollectivePollerNodeReady.new(client,listener)
reqids = Array.new
requid = poller.send()

reqids << requid
pp reqids
threads.each{|t|t.join}
