#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require 'mcollective'
require 'poller'
require 'listener'
Global = Hash.new
sema = Mutex.new
include XYZ::CommandAndControl

#problem seems to be when mcollective clients created in seperate threads
#if this case should set up a client pool that is gaurentedd to run in one thread across multiple users
CauseError = true
ErrorType = :ruby_error 
#ErrorType = :thread_block

def create_clients(num)
  (1..num).each do |i|
    Global[i] = CauseError ? nil : MCollective::Client.new("/etc/mcollective/client.cfg")
  end
end

def top(index)
  unless CauseError
    while Global[index].nil?
    sleep 0.3
  end
  client = Global[index]
  end
  client ||= MCollective::Client.new("/etc/mcollective/client.cfg")
  listener = McollectiveListener.new(client)
  threads = Array.new
  threads << Thread.new do
    i = 0
    count = 10
    if CauseError
      count = 1 if ErrorType == :ruby_error
      count = 10 if ErrorType == :thread_block
    end
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
top_threads << Thread.new{create_clients(num)}
(1..num).each do |i|
  top_threads << Thread.new{top(i)}
end
top_threads.each{|t2|t2.join}
