#!/usr/bin/env ruby
require 'rubygems'
require 'json'

# TBD: below is just temp until make into gems
project = File.expand_path('../', File.dirname(__FILE__)) + "/"
root = File.expand_path('../../', File.dirname(__FILE__)) + "/"
SYSTEM_DIR = root + 'system/'
CORE_MODEL_DIR  = root + 'core_model/'

require root + 'utils/utils'

# TBD: might change, but this needs to be done before otehr includes
XYZ::Config.process_config_file("/etc/reactor8/worker.conf")

require SYSTEM_DIR + 'cache'
require SYSTEM_DIR + 'messaging'

# TBD: can just include a smaller subset below
require project + 'model/init'


XYZ::MemoryCache.set_cache_servers(XYZ::Config[:memcache_servers] || [])

XYZ::Config.get_params().each{|p|
  print "config_param #{p} = #{XYZ::Config[p].inspect}\n"
}
queue = XYZ::Config[:queue] || ARGV[0] || "default"
partition_function = XYZ::Config[:partition_function] || lambda{|x|"default"}
msg_bus_server = XYZ::Config[:msg_bus_server] || "localhost"
scope = XYZ::Config[:scope]
c = 2
attr_ids = XYZ::Object.get_contained_attribute_ids(XYZ::IDHandle[:uri => scope,:c => c])

w = XYZ::Worker.new(queue)

attr_ids.each{|id|
  if partition_function.call(id) == queue
    print "adding #{id}\n"
    mp = XYZ::AttributeLinkMessageProcessor.new(XYZ::IDHandle[:c => c, :guid => id])
    w.add_processor(mp) 
  end
}
print "process id is: #{Process.pid}\n"
w.start msg_bus_server, :user => "worker", :pass => "worker"

