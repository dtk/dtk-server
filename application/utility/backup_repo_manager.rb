#!/usr/bin/env ruby
# TODO: inner loop can stop because of timeouts; check whetehr on client side or server(s) side
require 'rubygems'
require 'pp'
require File.expand_path("../require_first",File.dirname(__FILE__))
dtk_require_common_library()
r8_require("../../repo_manager_client/lib/repo_manager_client.rb")

remote_repo_base_url = "http://ec2-174-129-28-204.compute-1.amazonaws.com:7000"
mirror_host = 'ec2-50-16-199-149.compute-1.amazonaws.com' #ARGV[0]
mirror_base_url = "http://#{mirror_host}:7000"


include DTK

remote_repo_client = RepoManagerClient.new(remote_repo_base_url)

username = remote_repo_client.get_server_dtk_username()
rsa_pub_key = remote_repo_client.get_ssh_rsa_pub_key()
remote_repo_client.update_ssh_known_hosts(mirror_host)

mirror_client = RepoManagerClient.new(mirror_base_url)
pp mirror_client.add_user(username,rsa_pub_key,:noop_if_exists => true)

remote_repo_client = RepoManagerClient.new(remote_repo_base_url)
response =  remote_repo_client.list_repos()
remote_modules = response.map{|r|r["repo_name"]}
pp [:remote_modules,remote_modules]


remote_modules.each do |repo_name|
  # TODO: below is no-op if repo exsits; so if different user the specfied users rights not included; so have explicit set users rights
  mirror_client.create_repo(username,repo_name,"RW+")
  mirror_client.set_user_rights_in_repo(username,repo_name,"RW+")

  pp "created or found mirror_repo  #{repo_name}"
  master_branch = remote_repo_client.create_branch_instance(repo_name,"master")
  pp response =  master_branch.push_to_mirror(mirror_host)
end
