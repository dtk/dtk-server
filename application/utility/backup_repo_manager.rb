#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require File.expand_path("../require_first",File.dirname(__FILE__))
r8_require("../../repo_manager_client/lib/repo_manager_client.rb")
repo_name = ARGV[0]
rest_base_url = 'http://ec2-23-20-6-192.compute-1.amazonaws.com:7000' #ARGV[1]

username = 'test_user'
client = DTK::RepoManagerClient.new(rest_base_url)
rsa_pub_key = File.open('/root/.ssh/id_rsa.pub').read
pp client.add_user(username,rsa_pub_key,:noop_if_exists => true)
pp client.create_repo(username,repo_name,"RW+")
