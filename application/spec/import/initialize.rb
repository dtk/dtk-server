#!/usr/bin/env ruby
#general initial
require  File.expand_path('common', File.dirname(__FILE__))
options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: initialize.rb [--delete]"

   # Define the options, and what they do
   opts.on( '-d', '--delete', 'Delete module repos' ) do
     options[:delete] = true
   end
end.parse!

server = R8Server.new("superuser","all")
server.create_repo_user_r8server?()
server.create_public_library?()

=begin

Root = File.expand_path('../../', File.dirname(__FILE__))
require Root + '/app'
include XYZ
def model_handle(model_name)
  c = 2
  ModelHandle.new(c,model_name)
end

#TODO: need to better handle who is managing users
user_mh = model_handle(:user)
super_user_obj = User.create_user_in_groups?(user_mh,"superuser")
user_group_mh = user_mh.createMH(:user_group)

#create r8_server repo user and public library under superuser, group all
CurrentSession.new.set_user_object(super_user_obj)
group_obj = UserGroup.get_all_group(user_group_mh)
repo_user_mh = user_mh.createMH(:model_name => :repo_user, :group_id => group_obj[:id])
RepoUser.create_r8server?(repo_user_mh)
public_library_mh = repo_user_mh.createMH(:library)
Library.create_public_library?(public_library_mh)
=end
#TODO: not sure if btter to go in bootstrap or clear
XYZ::RepoManager.delete_all_repos() if options[:delete]


