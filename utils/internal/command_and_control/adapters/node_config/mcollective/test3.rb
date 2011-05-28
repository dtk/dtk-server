#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require 'mcollective'
require 'poller'
require 'listener'

#get blocking behavior if client is initialized in a thread (or seperate threads
client1 = nil #MCollective::Client.new("/etc/mcollective/client.cfg")
client2 = nil #MCollective::Client.new("/etc/mcollective/client.cfg")

def top(client=nil)
  client ||= MCollective::Client.new("/etc/mcollective/client.cfg")
  include XYZ::CommandAndControl
  listener = McollectiveListener.new(client)
  threads = Array.new
  threads << Thread.new do
    i = 0
    until i > 1
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
top_threads << Thread.new{top(client1)}
top_threads << Thread.new{top(client2)}
top_threads.each{|t2|t2.join}
