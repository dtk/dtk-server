#!/usr/bin/env ruby
# break this into two functions; one to load the library under user r8_library_user and another to add object sthat wil be under the user (what is in the test data project and target; (write the add user so that it can be used when this is driven from controller)

import_file = ARGV[0]
username = ARGV[1]
container_uri = "/"
flag = "r8meta_yaml"
Library = "test" #TODO: stub 

Root = File.expand_path('../', File.dirname(__FILE__))
require 'rubygems'
require "#{Root}/config/config.rb"

BaseDir = R8::Config[:repo][:base_directory]
Implementation = {:version => "0.10.0"}

def add_user_in_group?(username,groupname)
  user_mh = model_handle(:user)
  user_id = XYZ::Model.create_from_row?(user_mh,username,{:username => username}).get_id()
  group_id = XYZ::Model.create_from_row?(model_handle(:user_group),groupname,{:groupname => groupname}).get_id()
  XYZ::Model.create_from_row?(model_handle(:user_group_relation),"#{username}-#{groupname}",{:user_id => user_id, :user_group_id => group_id})
  [XYZ::User.get_user(user_mh,username),group_id]
end

def model_handle(model_name)
  c = 2
  XYZ::ModelHandle.new(c,model_name)
end


def load_component_opts(type)
  files = Dir.glob("#{BaseDir}/*/r8meta.*.#{TypeMapping[type]}")
  if files.empty? 
    {} 
  else
    {:r8meta => {:type => type, :library => Library, :files => files}}
  end
end
TypeMapping = {
  :yaml => "yml"
}

opts = 
  case flag 
    when "delete" then {:delete => true} 
    when "r8meta_yaml" then load_component_opts(:yaml)
    else {}
  end

require Root + '/app'
add_user_in_group?(username,"user-#{username}")
user_obj,all_group_id = add_user_in_group?(username,"all")


container_idh = XYZ::IDHandle[:c => 2, :uri => container_uri, :user_id => user_obj[:id], :group_id => all_group_id]
opts.merge!(:username => username)
opts.merge!(:add_implementations => {:version => Implementation[:version], :library => Library, :base_directory => BaseDir})

XYZ::CurrentSession.new.set_user_object(user_obj)
XYZ::Object.import_objects_from_file(container_idh,import_file,opts)


