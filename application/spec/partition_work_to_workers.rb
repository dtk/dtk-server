#!/usr/bin/env ruby
require 'rubygems'
require 'json'

# TBD: order below matters
root = File.expand_path('../../', File.dirname(__FILE__))
require root + '/utils/internal/helper/config.rb'
XYZ::Config.process_config_file("/etc/reactor8/server.conf")
require root + '/project1/app'


XYZ::Config.get_params().each{|p|
  print "config_param #{p} = #{XYZ::Config[p].inspect}\n"
}
partition_function = XYZ::Config[:partition_function] ||  lambda{|object_id| "default"}
scope = XYZ::Config[:scope]
msg_bus_server = XYZ::Config[:msg_bus_server] || "localhost"

c = 2
attr_ids = XYZ::Object.get_contained_attribute_ids(XYZ::IDHandle[:uri => scope,:c => c])
object_ids_assigns = {}
attr_ids.each{|object_id|
   object_ids_assigns[object_id] = partition_function.call(object_id)
}
XYZ::Worker.bind_queues(msg_bus_server,object_ids_assigns)


