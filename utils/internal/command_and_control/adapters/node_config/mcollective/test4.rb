#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require 'mcollective'
require 'poller'
require 'listener'
Global = Hash.new
Sema = Mutex.new
include XYZ::CommandAndControl

def top()
  client = nil
  Sema.synchronize{client = MCollective::Client.new("/etc/mcollective/client.cfg")}
  listener = McollectiveListener.new(client)
  threads = Array.new
  threads << Thread.new do
    i = 0
    count = 10
    until i > count
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
num = 2
(1..num).each do |i|
  top_threads << Thread.new{top()}
end
top_threads.each{|t2|t2.join}
