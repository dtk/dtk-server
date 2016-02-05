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
# TODO: should be made a rspec procedure
require 'rubygems'
require 'pp'
require File.expand_path('../require_first', File.dirname(__FILE__))
r8_require_common_lib('auxiliary', 'errors', 'log')
r8_require('../../repo_manager_client/lib/repo_manager_client.rb')

repo_host = 'ec2-50-16-199-149.compute-1.amazonaws.com' #ARGV[0]
repo_base_url = "http://#{repo_host}:7000"

include DTK

client = RepoManagerClient.new(repo_base_url)
username = 'test_user'
mod_name = 'test_repo2'
rsa_pub_key = Common::Aux.get_ssh_rsa_pub_key()
module_name_params = {
  name: mod_name,
  namespace: 'r8',
  type: :component
}
create_module_params = {
  username: username,
  access_rights: 'RW+',
  tags: { internal_id: 1 },
  noop_if_exists: true,
  #  :enable_all_users => true
}.merge(module_name_params)

client.create_module(create_module_params)
pp client.list_modules()
pp client.get_module_info(module_name_params)
pp client.delete_module(module_name_params)

users = client.list_users()

user_match = users.select { |u| u['username'] == username }
if user_match.size != 1
  fail Error.new("Unexpected selet on users found (#{user_match.inspect}")
end
pp user_match.first
pp client.delete_user(user_match.first['id'])