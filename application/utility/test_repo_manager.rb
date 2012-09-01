#!/usr/bin/env ruby
#TODO: should be made a rspec procedure
require 'rubygems'
require 'pp'
require File.expand_path("../require_first",File.dirname(__FILE__))
r8_require_common_lib("aux","errors","log")
r8_require("../../repo_manager_client/lib/repo_manager_client.rb")

repo_host = 'ec2-50-16-199-149.compute-1.amazonaws.com' #ARGV[0]
repo_base_url = "http://#{repo_host}:7000"


include DTK

client = RepoManagerClient.new(repo_base_url)
username='test_user'
mod_name='test_repo2'
rsa_pub_key = Common::Aux.get_ssh_rsa_pub_key()
pp client.create_user(username,rsa_pub_key,:update_if_exists => true)

create_module_params = {
  :username => username,
  :name => mod_name,
  :access_rights => "RW+", 
  :type => :component, 
  :tags => {:internal_id => 1},
  :noop_if_exists => true, 
#  :enable_all_users => true
}
pp client.create_module(create_module_params)
pp client.list_modules()
users = client.list_users()
pp users
user = users.find{|u|u["username"] == username}
pp client.display_module(:name => mod_name)
pp client.delete_module(:name => mod_name)
pp client.delete_user(user[:id])
