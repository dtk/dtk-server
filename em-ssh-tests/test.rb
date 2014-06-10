#!/usr/bin/env ruby
require 'eventmachine'
require "em-ssh"
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
      # capture all stderr and stdout output from a remote process
      ssh.exec!('uname -a').tap {|r| puts "\nuname: #{r}"}

      # capture only stdout matching a particular pattern
      stdout = ""
      ssh.exec!("ls -l /home/#{user}") do |channel, stream, data|
        stdout << data if stream == :stdout
      end
      puts "\n#{stdout}"

      # run multiple processes in parallel to completion
      ssh.exec('ping -c 1 www.google.com')
      ssh.exec('ping -c 1 www.yahoo.com')
      ssh.exec('ping -c 1 www.rakuten.co.jp')

      #open a new channel and configure a minimal set of callbacks, then wait for the channel to finishes (closees).
      channel = ssh.open_channel do |ch|
        ch.exec "/usr/bin/ruby /home/rich/exec.rb" do |ch, success|
          raise "could not execute command" unless success

          # "on_data" is called when the process writes something to stdout
          ch.on_data do |c, data|
            $stdout.print data
          end

          # "on_extended_data" is called when the process writes something to stderr
          ch.on_extended_data do |c, type, data|
            $stderr.print data
          end

          ch.on_close { puts "done!" }
        end
      end

      channel.wait

      ssh.close
      EM.stop
    end
  end
end
