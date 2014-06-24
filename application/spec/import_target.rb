#!/usr/bin/env ruby
# break this into two functions; one to load the library under user r8_library_user and another to add object sthat wil be under the user (what is in the test data project and target; (write the add user so that it can be used when this is driven from controller)

import_file = ARGV[0]
username = ARGV[1]
container_uri = "/"

Root = File.expand_path('../', File.dirname(__FILE__))

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

require Root + '/app'
user_obj, user_group_id = add_user_in_group?(username,"user-#{username}")

container_idh = XYZ::IDHandle[:c => 2, :uri => container_uri, :user_id => user_obj[:id], :group_id => user_group_id]
opts = {:username => username}

XYZ::CurrentSession.new.set_user_object(user_obj)
XYZ::Object.import_objects_from_file(container_idh,import_file,opts)


