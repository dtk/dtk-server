require 'rubygems'
require 'faye'
require 'pp'
require 'eventmachine'

EM.run do
  client = Faye::Client.new('http://localhost:9292/faye')
  client.subscribe('/foo') do |message|
    puts message.inspect
  end
  client.publish('/foo', 'text' => 'Hello world')
end
