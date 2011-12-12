#!/usr/bin/env ruby
#adds user, his or her private 
require File.expand_path('common', File.dirname(__FILE__))

options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: add_user.rb USERNAME [--create-private]"

   # Define the options, and what they do
   opts.on( '-p', '--create-private', 'Create private library ' ) do
     options[:create_private] = true
   end
end.parse!
username = ARGV[0]
server = R8Server.new(username)

server.create_repo_user_client?()

server.create_users_private_library?() if options[:create_private]

server.create_users_private_target?()

