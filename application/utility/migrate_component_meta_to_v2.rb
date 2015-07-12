#!/usr/bin/env ruby
# general initial
require File.expand_path('common', File.dirname(__FILE__))
module_name = ARGV[0]
server = R8Server.new('superuser', groupname: 'all')
new_meta_full_path = server.migrate_metafile(module_name)
STDOUT << new_meta_full_path
STDOUT << "\n"
