#!/usr/bin/env ruby

require "rubygems"
require 'mq'

  class Foo 
    def add_one(x)
      x+1
    end
  end
  class Foo2 
    def add_to_array(a)
      a.map{|x|x+1}
    end
  end

  class Foo3 
    def processx(x)
      print "here1\n"
      sleep(5)
      print "here2\n"
      {:p => x}
    end
  end
print "here0\n"

AMQP.start(:host => '10.5.5.6') do

  def log *args
    p args
  end


  server1 = MQ.new.rpc('foo', Foo.new)
  server2 = MQ.new.rpc('foo2', Foo2.new)
  server3 = MQ.new.rpc('foo3', Foo3.new)

  client1 = MQ.new.rpc('foo')

  client1.add_one(4) do |res|
    log 'client1', :add_one => res
  end

  client2 = MQ.new.rpc('foo2')
  client2.add_to_array [7, 8 ,9] do |res|
    log 'client2', :add_to_array => res
  end

  client3 = MQ.new.rpc('foo3')
  hash = {:x => {:y => :z}}
  client3.processx hash do |res|
    log 'client3', res
    AMQP.stop{ EM.stop }
  end
end
