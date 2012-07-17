#!/usr/bin/env ruby
#general initial
require File.expand_path('common', File.dirname(__FILE__))
module_name = ARGV[0]
server = R8Server.new("superuser","all")
STDOUT << JSON.pretty_generate(server.get_component_meta_file(module_name))

