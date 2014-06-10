#!/usr/bin/env ruby
require 'eventmachine'
require "em-ssh"
require 'pp'
EM.run do
  host =  ARGV[0]
  user = ARGV[1]
  password = ARGV[2]
  EM::Ssh.start(host, user, :password => password) do |connection|
    connection.errback do |err|
      $stderr.puts "#{err} (#{err.class})"
      EM.stop
    end
    connection.callback do |ssh|
      # capture only stdout matching a particular pattern
      stdout = ""
      ssh.exec!("ls -l /home/#{user}") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      puts "\n#{stdout}"

      # run multiple processes in parallel to completion
      ssh.exec("touch 1.txt && echo 'start1' && sleep 1 && echo 'end1'")
      ssh.exec("touch 2.txt && echo 'start2' && sleep 1 && echo 'end2'")
      ssh.exec("touch 3.txt && echo 'start3' && sleep 1 && echo 'end3'")
    end
  end
end
