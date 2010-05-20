#!/usr/bin/env ruby

require 'rubygems'
require 'mq'

AMQP.start do
  MQ.queue("control").publish("test")
  AMQP::stop {EM.stop}
end

