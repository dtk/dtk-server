#!/usr/bin/env ruby
import_file = ARGV[0]
username = ARGV[1]
container_uri = "/"
flag = "r8meta_yaml"
Library = "test" #TODO: stub 

Root = File.expand_path('../', File.dirname(__FILE__))
require "#{Root}/config/environment_config.rb"

BaseDir = R8::EnvironmentConfig::CoreCookbooksRoot
Implementation = {:type => :chef, :version => "0.10.0"}

def add_user_and_group(username)
  exists_user,user_id = add_if_does_not_exist(:user,:username,username)
  exists_group,group_id = add_if_does_not_exist(:group,:groupname,username)
  unless exists_user and exists_group
    XYZ::Model.create_from_rows(model_handle(:user_group_relation),[{:user_id => user_id, :group_id => group_id}])
  end
  [user_id,group_id]
end

def add_if_does_not_exist(model_name,attr,val)
  sp_hash = {:cols => [:id],:filter => [:eq,attr,val]}
  mh = model_handle(model_name)
  matching_obj = XYZ::Model.get_objects_from_sp_hash(mh,sp_hash).first
  if id = matching_obj && matching_obj[:id]
    exists = true
  else
    exists = false
    idh = XYZ::Model.create_from_rows(mh,[{attr => val}]).first
    id = idh.get_id()
  end
  [exists,id]
end

def model_handle(model_name)
  c = 2
  XYZ::ModelHandle.new(c,model_name)
end


def load_component_opts(type)
  files = Dir.glob("#{BaseDir}/*/r8meta.#{TypeMapping[type]}")
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
add_user_and_group(username)
exit
opts.merge!(:add_implementations => {:type => Implementation[:type], :version => Implementation[:version], :library => Library, :base_directory => BaseDir})
XYZ::Object.import_objects_from_file(XYZ::IDHandle[:c => 2, :uri => container_uri],import_file,opts)


