#!/usr/bin/env ruby

username = "superuser"
import_file = File.expand_path('test_data/library_node_data.json', File.dirname(__FILE__))

Root = File.expand_path('../', File.dirname(__FILE__))
require Root + '/app'
include XYZ


def model_handle(model_name)
  c = 2
  ModelHandle.new(c,model_name)
end

user_mh = model_handle(:user)
super_user_obj = User.create_user_in_groups?(user_mh,username)

CurrentSession.new.set_user_object(super_user_obj)
all_group_obj = UserGroup.get_by_groupname(user_mh.createMH(:user_group),"all")
container_idh = IDHandle[:c => 2, :uri => "/", :group_id => all_group_obj[:id]]
opts = {:username => username} #TODO: do we need this
Model.import_objects_from_file(container_idh,import_file,opts)


