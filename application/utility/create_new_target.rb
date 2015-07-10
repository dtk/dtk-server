#!/usr/bin/env ruby
# general initial
require File.expand_path('common', File.dirname(__FILE__))
options = {}
OptionParser.new do|opts|
   opts.banner = 'Usage: create_new_target.rb USER-NAME TARGET-NAME'
end.parse!
username = ARGV[0]
target_name = ARGV[1]
server = R8Server.new(username)
server.create_new_target?(target_name)
