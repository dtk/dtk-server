#!/usr/bin/env ruby
require 'rubygems'
require 'stomp'
require 'pp'

$agents = ["get_log_fragment","discovery","chef_solo"]
def receive()
  host = 'localhost'
  port = 6163
  user = 'mcollective'
  password = 'marionette'
  connection = ::Stomp::Connection.new(user, password, host, port, true)
  $agents.each do |a|
    connection.subscribe("/topic/mcollective.#{a}.reply")
    connection.subscribe("/topic/mcollective.#{a}.command")
  end
  loop do
    msg = connection.receive
    decoded_msg = Marshal.load(msg.body)#Security.decodemsg(msg.body)
    decoded_msg[:body] = Marshal.load(decoded_msg[:body])
    pp ['got a message', decoded_msg]
  end
end

receive()

