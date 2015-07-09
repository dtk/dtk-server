#!/usr/bin/env ruby
# TODO: should be made a rspec procedure
require 'rubygems'
require 'pp'
require File.expand_path('../require_first',File.dirname(__FILE__))
r8_require_common_lib('auxiliary','errors','log')
r8_require('../../repo_manager_client/lib/repo_manager_client.rb')

repo_host = 'ec2-50-16-199-149.compute-1.amazonaws.com' #ARGV[0]
repo_base_url = "http://#{repo_host}:7000"

include DTK

client = RepoManagerClient.new(repo_base_url)
username='test_user'
mod_name='test_repo2'
rsa_pub_key = Common::Aux.get_ssh_rsa_pub_key()
module_name_params = {
  name: mod_name,
  namespace: 'r8',
  type: :component
}
create_module_params = {
  username: username,
  access_rights: 'RW+',
  tags: {internal_id: 1},
  noop_if_exists: true,
  #  :enable_all_users => true
}.merge(module_name_params)

client.create_module(create_module_params)
pp client.list_modules()
pp client.get_module_info(module_name_params)
pp client.delete_module(module_name_params)

users = client.list_users()

user_match = users.select{|u|u['username'] == username}
if user_match.size != 1
  raise Error.new("Unexpected selet on users found (#{user_match.inspect}")
end
pp user_match.first
pp client.delete_user(user_match.first['id'])
