#!/usr/bin/env ruby
require File.expand_path('common', File.dirname(__FILE__))
server = R8Server.new('superuser',groupname: 'all')
server.create_repo_user_instance_admin?()
# TODO: this is additive; probably want version that deletes also
server.create_public_library_nodes?()
