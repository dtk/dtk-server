#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require File.expand_path("../require_first",File.dirname(__FILE__))
r8_require_common_lib("aux")
r8_require("../../repo_manager_client/lib/repo_manager_client.rb")
#TODO: should move some of routines in dtk-clone core to dtk common or make dtk api package
r8_require("../../../dtk-client/lib/core")
class API <  DTK::Client::Conn
  def get(path)
    url = rest_url(path)
    ::DTK::Common::Rest::Response.new(json_parse_if_needed(get_raw(url)))
  end

  def post(path,body=nil)
    url = rest_url(path)
    ::DTK::Common::Rest::Response.new(json_parse_if_needed(post_raw(url,body)))
  end
end
###

rest_base_url = 'http://ec2-23-20-6-192.compute-1.amazonaws.com:7000' #ARGV[0]
dtk_conn = API.new()

response =  dtk_conn.post("component_module/list_remote")
raise Error.new(response.inspect) unless response.ok?
remote_component_modules = response.data().map{|r|r["display_name"]}
pp [:remote_component_modules,remote_component_modules]

mirror_client = ::DTK::RepoManagerClient.new(rest_base_url)
username = ::DTK::Common::Aux.dtk_instance_repo_username()
rsa_pub_key = ::DTK::Common::Aux.get_ssh_rsa_pub_key()
pp mirror_client.add_user(username,rsa_pub_key,:noop_if_exists => true)

remote_component_modules.each do |repo_name|
  mirror_client.create_repo(username,repo_name,"RW+")
  pp "created mirror_repo  #{repo_name}"
end
