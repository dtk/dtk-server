#!/usr/bin/env ruby
#break this into two functions; one to load the library under user r8_library_user and another to add object sthat wil be under the user (what is in the test data project and target; (write the add user so that it can be used when this is driven from controller)

import_file = ARGV[0]
username = ARGV[1]
container_uri = "/"
flag = "r8meta_yaml"
Library = "test" #TODO: stub 

Root = File.expand_path('../', File.dirname(__FILE__))
require "#{Root}/config/environment_config.rb"

BaseDir = R8::EnvironmentConfig::CoreCookbooksRoot
Implementation = {:version => "0.10.0"}

def add_user_in_group(username,groupname)
  exists_user,user_id = add_if_does_not_exist(:user,username,:username,username)
  exists_group,group_id = add_if_does_not_exist(:user_group,groupname,:groupname,groupname)
  unless exists_user and exists_group
    create_row(model_handle(:user_group_relation),{:ref => "#{username}-#{groupname}",:user_id => user_id, :user_group_id => group_id})
  end
  XYZ::User.get_user(model_handle(:user),username)
end

def add_if_does_not_exist(model_name,ref,attr,val)
  sp_hash = {:cols => [:id],:filter => [:eq,attr,val]}
  mh = model_handle(model_name)
  matching_obj = XYZ::Model.get_objs(mh,sp_hash).first
  if id = matching_obj && matching_obj[:id]
    exists = true
  else
    exists = false
    id = create_row(mh,{:ref => ref, attr => val}).first[:id]
  end
  [exists,id]
end

def create_row(model_handle,scalar_assigns_x)
  scalar_assigns = scalar_assigns_x.dup
  ref = scalar_assigns.delete(:ref)
  factory = XYZ::IDHandle[:c => model_handle[:c],:uri => "/#{model_handle[:model_name]}", :is_factory => true]
  XYZ::Model.create_from_hash(factory,{ref => scalar_assigns}) 
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
user_obj = add_user_and_group(username)

container_idh = XYZ::IDHandle[:c => 2, :uri => container_uri, :user_id => user_obj[:id], :group_ids => user_obj[:group_ids]]
opts.merge!(:username => username)
opts.merge!(:add_implementations => {:version => Implementation[:version], :library => Library, :base_directory => BaseDir})

XYZ::CurrentSession.new.set_user_object(user_obj)
XYZ::Object.import_objects_from_file(container_idh,import_file,opts)


