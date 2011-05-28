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
threads = Array.new
stop = nil
threads << Thread.new do
  until stop
    msg = listener.process_event()
    pp [:received,msg]
  end
end
poller = McollectivePollerNodeReady.new(client)
requid = poller.send
sleep 1
listener.add_request_id(requid)
stop = true
threads.each{|t|t.join}
