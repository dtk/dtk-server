#!/usr/bin/env ruby
# adds user, his or her private 
require File.expand_path('common', File.dirname(__FILE__))

options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: add_user.rb USERNAME [EC2-REGION] [--create-private [MODULE_SEED_LIST]]"

  # Define the options, and what they do
  opts.on( '-p', '--create-private [MODULE_SEED_LIST]', 'Create private library ' ) do |module_names|
    options[:create_private] = true
    options[:module_names] = module_names && module_names.split(",")
  end
end.parse!
username = ARGV[0]
ec2_region = ARGV[1]
server = R8Server.new(username)

server.create_repo_user_for_nodes?()

server.create_users_private_library?() if options[:create_private]

idhs = server.create_users_private_target?(nil,ec2_region)

=begin
# DEPREACTE
if options[:module_names]
  library_impls = server.add_modules_from_external_repo_dir(options[:module_names])
  (idhs[:project_idhs]||[]).each do |project_idh|
    project = project_idh.create_object()
    server.add_modules_workspaces(project,library_impls)
  end
end
=end

