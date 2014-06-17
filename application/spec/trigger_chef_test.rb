#!/usr/bin/env ruby
require 'rubygems'
require 'mq'
require 'json'
require 'restclient'


# TBD: below is just temp until make into gems
root = File.expand_path('../../', File.dirname(__FILE__)) + "/"
SYSTEM_DIR = root + 'system/'

require root + 'utils/utils'
XYZ::Config.process_config_file("/etc/reactor8/worker.conf")

require SYSTEM_DIR + 'messaging'
msg_bus_server = XYZ::Config[:msg_bus_server] || "localhost"

Rest_server = "10.5.5.6"
Node = ARGV[0] || "/library/saved/node/pg"

def get_node_guid(node_uri)
  json_node_id = RestClient.get("http://#{Rest_server}:7000/get_guid#{node_uri}.json")
  JSON.parse(json_node_id.to_s)["guid"] 
end


node_id = get_node_guid(Node)
print "node_id = #{node_id.inspect}\n" 
node_key = node_id.to_s


XYZ::R8AMQP.start(:host => msg_bus_server) do
   mq = XYZ::R8MQ.new
   mq.topic('nodes').publish("run", :key => node_key)
   XYZ::R8AMQP.graceful_stop()
end
