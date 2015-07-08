#!/usr/bin/env ruby
require 'rubygems'
require 'stomp'
require 'pp'

msg_types = {
  get_log_fragment: [:command],
  get_log_fragment: [],
  discovery: [],
  chef_solo: [],
  puppet_apply: [],
  git_access: [],
  netstat: [],
  tail: []
}
def listen_for(msg_types)
  host = 'localhost'
  port = 6163
  user = 'mcollective'
  password = 'marionette'
  connection = ::Stomp::Connection.new(user, password, host, port, true)
  msg_types.each do |a,dirs|
    dirs =  [:command,:reply] if dirs.empty?
    dirs.each do |dir|
      connection.subscribe("/topic/mcollective.#{a}.#{dir}")
    end
  end
  loop do
    msg = connection.receive
    decoded_msg = Marshal.load(msg.body)#Security.decodemsg(msg.body)
    decoded_msg[:body] = Marshal.load(decoded_msg[:body])
    pp ['got a message', decoded_msg]
    STDOUT.flush
  end
end

listen_for(msg_types)
