#!/usr/bin/env ruby
#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# general initial
require File.expand_path('common', File.dirname(__FILE__))

options = {}
OptionParser.new do|opts|
   opts.banner = 'Usage: initialize.rb [--delete]'

   # Define the options, and what they do
   opts.on('-d', '--delete', 'Delete module repos') do
     options[:delete] = true
   end
end.parse!

server = R8Server.new('superuser', groupname: 'all')
server.create_repo_user_instance_admin?()
server.create_public_library?(include_default_nodes: true)

# TODO: not sure if better to go in bootstrap or clear
XYZ::RepoManager.delete_all_repos() if options[:delete]