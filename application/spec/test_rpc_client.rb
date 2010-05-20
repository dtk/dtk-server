#!/usr/bin/env ruby

require "rubygems"
require 'mq'

print "here0\n"

AMQP.start(:host => '10.5.5.6') do

  def log *args
    p args
  end

  client3 = MQ.new.rpc('foo3')
  hash = {:x => {:y => :z}}
  client3.processx hash do |res|
    log 'client3', res
    AMQP.stop{ EM.stop }
  end

  client1 = MQ.new.rpc('foo')

  client1.add_one(4) do |res|
    log 'client1', :add_one => res
  end

  client2 = MQ.new.rpc('foo2')
  client2.add_to_array [7, 8 ,9] do |res|
    log 'client2', :add_to_array => res
  end

end
