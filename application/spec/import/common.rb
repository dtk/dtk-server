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

  def create_public_library?()
    library_mh = pre_execute(:repo_user)
    Library.create_public_library?(library_mh)
  end

  private
  attr_reader :user_mh, :user_obj
  def pre_execute(model_name=nil)
    CurrentSession.new.set_user_object(user_obj)
    model_name && user_mh.createMH(model_name)
  end
  def model_handle(model_name)
    c = 2
    ModelHandle.new(c,model_name)
  end
end

