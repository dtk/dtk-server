#!/usr/bin/env ruby
#TODO: fix up so that credential exchange is between repo managers not wrt to this client

require 'rubygems'
require 'pp'
require File.expand_path("../require_first",File.dirname(__FILE__))
r8_require_common_lib("aux","errors","log")
r8_require("../../repo_manager_client/lib/repo_manager_client.rb")

remote_repo_base_url = "http://ec2-174-129-28-204.compute-1.amazonaws.com:7000"
mirror_host = 'ec2-50-16-199-149.compute-1.amazonaws.com' #ARGV[0]
mirror_base_url = "http://#{mirror_host}:7000"


include DTK
include DTK::Common

mirror_client = RepoManagerClient.new(mirror_base_url)
username = Aux.dtk_instance_repo_username()
rsa_pub_key = Aux.get_ssh_rsa_pub_key()
pp mirror_client.add_user(username,rsa_pub_key,:noop_if_exists => true)

remote_repo_client = RepoManagerClient.new(remote_repo_base_url)
response =  remote_repo_client.list_repos()
remote_modules = response.map{|r|r["repo_name"]}
pp [:remote_modules,remote_modules]


remote_modules.each do |repo_name|
  mirror_client.create_repo(username,repo_name,"RW+") #TODO: may make this part of component/push_to_mirror call
  pp "created or found mirror_repo  #{repo_name}"
  master_branch = remote_repo_client.create_branch_instance(repo_name,"master")
  pp response =  master_branch.push_to_mirror(mirror_host)
end
