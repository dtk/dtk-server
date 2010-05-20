#!/usr/bin/env ruby

require 'rubygems'
require 'bunny'
require 'mq'
queue_names = ARGV[0] ? ARGV : ['foo']
client = nil
AMQP.start do
  MQ.queue('control').subscribe() do |msg|
  queue_names.each do |queue_name|
    if client.nil?
       client = Bunny.new
       client.start()
    end
    queue = nil
    begin
     queue = client.queue(queue_name, :passive => true)
     print "sent to queue #{queue_name}\n"
    rescue Exception => e
      print "queue #{queue_name} does not exist\n"
      client = nil
    end
    if queue
     queue.publish("This is a test message on queue #{queue_name}")
    end
  end
  client.stop() if client
  end
end



