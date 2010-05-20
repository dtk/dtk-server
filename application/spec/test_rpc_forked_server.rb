#!/usr/bin/env ruby

require "rubygems"
require 'mq'

  class Foo 
    def add_one(x)
      print "processing foo1\n"
      x+1
    end
  end
  class Foo2 
    def add_to_array(a)
      print "processing foo2\n"
      a.map{|x|x+1}
    end
  end

  class Foo3 
    def processx(x)
      print "processing foo3\n"
      print "here1\n"
      sleep(5)
      print "here2\n"
      {:p => x}
    end
  end

AMQP.class_eval do
  def self.set_settings(opts={})
    settings #TBD: to set @settings with defaults
    opts.each{|k,v| @settings[k] = v}
  end
end 

AMQP.set_settings :host => '10.5.5.6'
AMQP.start do
   AMQP.fork(1) do
     MQ.new.rpc('foo', Foo.new)
   end

   AMQP.fork(1) do
     MQ.new.rpc('foo2', Foo2.new)
   end
   AMQP.fork(1) do
    MQ.new.rpc('foo3', Foo3.new)
   end
end