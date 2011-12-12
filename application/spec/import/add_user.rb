#!/usr/bin/env ruby
#adds user, his or her private 
require File.expand_path('common', File.dirname(__FILE__))

options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: add_user.rb USERNAME [--add-nodes] [--create-public]"

   # Define the options, and what they do
   opts.on( '-a', '--add-nodes', 'Add library nodes in private library ' ) do
     options[:add_nodes] = true
   end
   opts.on( '-p', '--ctreate-public', 'Create public library ' ) do
     options[:craete_public] = true
   end
end.parse!
username = ARGV[0]


