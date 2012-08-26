#!/usr/bin/env ruby
require 'rubygems'
require 'pp'
require File.expand_path("../require_first",File.dirname(__FILE__))
r8_require_common_lib("aux","errors","log")
r8_require("../../repo_manager_client/lib/repo_manager_client.rb")
#TODO: should move some of routines in dtk-clone core to dtk common or make dtk api package
r8_require("../../../dtk-client/lib/core")

include DTK
include DTK::Common
class API <  Client::Conn
  def get(path)
    url = rest_url(path)
    handle_error do
      Rest::Response.new(json_parse_if_needed(get_raw(url)))
    end
  end

  def post(path,body=nil)
    url = rest_url(path)
    handle_error do 
      Rest::Response.new(json_parse_if_needed(post_raw(url,body)))
    end
  end
  def handle_error(&block)
    response = yield
    raise Error.new(response["errors"].inspect) unless response.ok?
    response
  end
end
###
mirror_host = 'ec2-50-16-199-149.compute-1.amazonaws.com' #ARGV[0]
mirror_base_url = "http://#{mirror_host}:7000"

dtk_conn = API.new()

response =  dtk_conn.post("component_module/list_remote")
remote_component_modules = response.data().map{|r|r["display_name"]}
pp [:remote_component_modules,remote_component_modules]

mirror_client = RepoManagerClient.new(mirror_base_url)
username = Aux.dtk_instance_repo_username()
rsa_pub_key = Aux.get_ssh_rsa_pub_key()
pp mirror_client.add_user(username,rsa_pub_key,:noop_if_exists => true)

remote_component_modules.each do |repo_name|
  mirror_client.create_repo(username,repo_name,"RW+") #TODO: may make this part of component/push_to_mirror call
  pp "created or found mirror_repo  #{repo_name}"
  #TODO: this needs to be changed to talk to remote manager, not the dtk instance
#  pp response =  dtk_conn.post("component_module/push_to_mirror",{:component_module_id => repo_name, :mirror_host => mirror_host})
end
