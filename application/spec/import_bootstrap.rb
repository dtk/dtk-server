#!/usr/bin/env ruby
username = ARGV[0]
delete_flag = ARGV[1]
raise "no username" unless username

Root = File.expand_path('../', File.dirname(__FILE__))

def model_handle(model_name)
  c = 2
  XYZ::ModelHandle.new(c,model_name)
end

require Root + '/app'
include XYZ
# TODO: need to better handle who is managing users
user_mh = model_handle(:user)
super_user_obj = User.create_user_in_groups?(user_mh,"superuser")
user_obj = User.create_user_in_groups?(user_mh,username)
user_group_mh = user_mh.createMH(:user_group)
#== under super user, group: all
# create r8_server repo user and public library under superuser, group all
CurrentSession.new.set_user_object(super_user_obj)
group_obj = UserGroup.get_all_group(user_group_mh)
repo_user_mh = user_mh.createMH(:model_name => :repo_user, :group_id => group_obj[:id])
RepoUser.create_r8server?(repo_user_mh)
public_library_mh = repo_user_mh.createMH(:library)
Library.create_public_library?(public_library_mh)
#######

# create a private library for user 
CurrentSession.new.set_user_object(user_obj)
group_obj = UserGroup.get_private_group(user_group_mh,username)
repo_user_mh = user_mh.createMH(:model_name => :repo_user, :group_id => group_obj[:id])
library_mh = repo_user_mh.createMH(:library)
Library.create_users_private_library?(library_mh)
RepoUser.create_r8client?(repo_user_mh,username)

# TODO: not sure if btter to go in bootstrap or clear
RepoManager.delete_all_repos() if delete_flag == "--delete" 

