#!/usr/bin/env ruby
#general initial
require 'rubygems'
require 'optparse'

Root = File.expand_path('../../', File.dirname(__FILE__))
require Root + '/app'

class R8Server
  include XYZ
  def initialize(username,groupname="private")
    @user_mh = model_handle(:user)
    @user_obj = User.create_user_in_groups?(user_mh,username)
    user_group_mh = user_mh.createMH(:user_group)
    group_obj = 
      case groupname 
       when "all" then UserGroup.get_all_group(user_group_mh) 
       when "private" then UserGroup.get_private_group(user_group_mh,username)
       else raise "Group (#{groupname})not treated"
      end
    @user_mh[:group_id] = group_obj[:id]
  end

  ###actions
  def create_repo_user_r8server?()
    repo_user_mh = pre_execute(:repo_user)
    RepoUser.create_r8server?(repo_user_mh)
  end

  def create_repo_user_client?()
    repo_user_mh = pre_execute(:repo_user)
    RepoUser.create_r8client?(repo_user_mh,username)
  end

  def create_public_library?(opts={})
    #TODO: hack; must unify; right now based on assumption on name that appears in import file
    if opts[:include_default_nodes]
      container_idh = pre_execute(:top)
      import_file = "#{Root}/spec/test_data/library_node_data.json" #TODO: hack
      Model.import_objects_from_file(container_idh,import_file)
    else
      library_mh = pre_execute(:library)
      Library.create_public_library?(library_mh)
    end
  end

  def create_users_private_library?()
    library_mh = pre_execute(:library)
    Library.create_users_private_library?(library_mh)
  end

  def create_users_private_target?(import_file=nil)
    #TODO: this is hack that should be fixed up
    container_idh = pre_execute(:top)
    import_file ||= "#{Root}/spec/test_data/target_data_set.json" #TODO: hack
    hash_content_with_generic_refs = Aux::hash_from_file_with_json(import_file) 
    users_ref = "private-#{username}"
    hash_content = transform_refs(users_ref,hash_content_with_generic_refs)
    Model.import_objects_from_hash(container_idh,hash_content)
  end
  def transform_refs(users_ref,hash_content_with_generic_refs)
    hash_content_with_generic_refs.inject({}) do |h,(top_model_name,rest)|
      to_add = {
        top_model_name => {
          users_ref => rest.values.first
        }
      }
      h.merge(to_add)
    end
  end
  private :transform_refs

  private
  attr_reader :user_mh, :user_obj
  def username()
    user_obj[:username]
  end
  def pre_execute(model_name=nil)
    CurrentSession.new.set_user_object(user_obj)
    if model_name 
      model_name == :top ? user_mh.create_top() : user_mh.createMH(model_name)
    end
  end
  def model_handle(model_name)
    c = 2
    ModelHandle.new(c,model_name)
  end
end

