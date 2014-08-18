#!/usr/bin/env ruby
# adds user, his or her private 
require File.expand_path('common', File.dirname(__FILE__))

options = Hash.new
OptionParser.new do|opts|
#   opts.banner = "Usage: add_user.rb USERNAME [EC2-REGION] [--create-private [MODULE_SEED_LIST]]"
   opts.banner = "Usage: add_user.rb USERNAME [EC2-REGION] --password PASSWORD"

  # Define the options, and what they do
  opts.on( '-p', '--password PASSWORD', "User's password") do |pw|
    options[:password] = pw
  end
end.parse!
username = ARGV[0]
ec2_region = ARGV[1]
server = R8Server.new(username,options)
server.create_repo_user_for_nodes?()

idhs = server.create_users_private_target?(nil,ec2_region)

