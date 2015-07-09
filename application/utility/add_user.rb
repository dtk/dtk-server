#!/usr/bin/env ruby
# adds user, his or her private
require File.expand_path('common', File.dirname(__FILE__))

options = {}
OptionParser.new do |opts|
   #   opts.banner = "Usage: add_user.rb USERNAME [EC2-REGION] [--create-private [MODULE_SEED_LIST]]"
   opts.banner = 'Usage: add_user.rb USERNAME [EC2-REGION] [--password PASSWORD] [-f PARAM-FILE]'

  # Define the options, and what they do
  opts.on('-p', '--password PASSWORD', "User's password") do |pw|
    options[:password] = pw
  end
  opts.on('-f', '--param-file PARAM-FILE', 'File with parameters') do |path|
    require 'yaml'
    param_hash =
      begin
        YAML.load(File.open(path).read) rescue nil
      end
    if param_hash
      ['password', 'catalog_username', 'catalog_password'].each do |k|
        if val = param_hash[k]
          options[k.to_sym] ||= val
        end
      end
    end
  end
end.parse!
username = ARGV[0]
ec2_region = ARGV[1]

# default is that catalog_username is set to username
options[:catalog_username] ||= username

server = R8Server.new(username, options)
server.create_repo_user_for_nodes?()

idhs = server.create_users_private_target?(nil, ec2_region)
