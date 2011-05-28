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

def top(client)
  include XYZ::CommandAndControl
  listener = McollectiveListener.new(client)
  
  threads = Array.new
  threads << Thread.new do
    i = 0
    until i > 10
      msg = listener.process_event()
      pp [Thread.current,msg]
      i += 1
    end
  end

  poller = McollectivePollerNodeReady.new(client,listener)
  poller.send()
  threads.each{|t|t.join}
end

top_threads = Array.new
top_threads << Thread.new{top(client)}
top_threads << Thread.new{top(client)}
top_threads.each{|t2|t2.join}
