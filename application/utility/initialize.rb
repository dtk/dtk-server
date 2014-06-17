#!/usr/bin/env ruby
# general initial
require File.expand_path('common', File.dirname(__FILE__))
options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: initialize.rb [--delete]"

   # Define the options, and what they do
   opts.on( '-d', '--delete', 'Delete module repos' ) do
     options[:delete] = true
   end
end.parse!

server = R8Server.new("superuser","all")
server.create_repo_user_instance_admin?()
server.create_public_library?(:include_default_nodes => true)

# TODO: not sure if better to go in bootstrap or clear
XYZ::RepoManager.delete_all_repos() if options[:delete]


