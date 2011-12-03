#!/usr/bin/env ruby
username = ARGV[0]
raise "no username" unless username

Root = File.expand_path('../', File.dirname(__FILE__))

def model_handle(model_name)
  c = 2
  XYZ::ModelHandle.new(c,model_name)
end

require Root + '/app'
include XYZ
#TODO: need to better handle who is managing users
user_mh = model_handle(:user)
super_user_obj = User.create_user_in_groups?(user_mh,"superuser")
User.create_user_in_groups?(user_mh,username)
CurrentSession.new.set_user_object(super_user_obj)
