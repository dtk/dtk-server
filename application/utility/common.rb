#!/usr/bin/env ruby
# general initial
require 'rubygems'
require 'optparse'
require 'sshkey'
require 'erubis'

require File.expand_path('library_nodes', File.dirname(__FILE__))

Root = File.expand_path('../', File.dirname(__FILE__))
require Root + '/app'

class R8Server
  include XYZ
  def initialize(username,opts={})
    groupname = opts[:groupname]||"private"
    @user_mh = model_handle(:user)
    @user_obj = User.create_user_in_groups?(user_mh,username,opts)
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
  def parse_dtk_model_file(file_path)
    content = File.open(file_path).read()
    Aux.convert_to_hash(content,:yaml)
  end

  def create_repo_user_instance_admin?()
    repo_user_mh = pre_execute(:repo_user)
    RepoUser.add_repo_user?(:admin,repo_user_mh)
  end

  def create_repo_user_for_nodes?()
    repo_user_mh = pre_execute(:repo_user)
    unless RepoUser.get_matching_repo_user(repo_user_mh, :type => :node)
      new_key =  ::SSHKey.generate(:type => "rsa")
      ssh_rsa_keys = {
        :public => new_key.ssh_public_key,
        :private => new_key.private_key
      }
      # dtk-node-dtkX should be in group 'all'
      user_mh = model_handle(:user)
      user_group_mh = user_mh.createMH(:user_group)
      group_obj = UserGroup.get_all_group(user_group_mh)
      repo_user_mh[:group_id] = group_obj[:id]
      RepoUser.add_repo_user(:node,repo_user_mh,ssh_rsa_keys)
    end
  end

  def create_public_library?(opts={})
    # TODO: hack; must unify; right now based on assumption on name that appears in import file
    if opts[:include_default_nodes]
      create_public_library_nodes?()
    else
      library_mh = pre_execute(:library)
      Library.create_public_library?(library_mh)
    end
  end

 def create_public_library_nodes?()
    container_idh = pre_execute(:top)
    hash_content = LibraryNodes.get_hash(:in_library => "public")
    hash_content["library"]["public"]["display_name"] ||= "public"
    Model.import_objects_from_hash(container_idh,hash_content)
  end

  def create_users_private_library?()
    library_mh = pre_execute(:library)
    Library.create_users_private_library?(library_mh)
  end

  def create_users_private_target?(import_file=nil,ec2_region=nil)
    container_idh = pre_execute(:top)
    users_ref = "private-#{username}"
    json_content = PrivateTargetTemplate.result(:project_ref => users_ref,:target_ref => users_ref,:ec2_region => ec2_region||"us-east-1")
    hash_content = JSON.parse(json_content)
    Model.import_objects_from_hash(container_idh,hash_content)

    # return idhs of new targets and new projects
    ret = {
      :target_idhs => ret_idhs("datacenter",hash_content,container_idh),
      :project_idhs => ret_idhs("project",hash_content,container_idh)
    }

    # create workspace
    unless project_idh = ret[:project_idhs].first
      Log.error("No project found so not creating a workspace")
      return ret
    end
    if ret[:project_idhs].size > 1
      Log.error("Unexpected taht multiple projects found; pikcing arbirary one for workspace")
    end
    (ret[:target_idhs]||[]).each{|target_idh|Workspace.create?(target_idh,project_idh)}

    ret
  end

  # TODO: this is hack that should be fixed up; no need to use josn here
  PrivateTargetTemplate = Erubis::Eruby.new <<eos
{
  "project": {
    "<%= project_ref %>": {
      "display_name": "Project 1",
      "description": "Project 1",
      "type": "puppet"
    }
  },
  "datacenter": {
    "<%= target_ref %>": {
      "display_name": "DTK_Test_Target",
      "description": "Free R8Network testing target, nodes will be up for 2 hours.",
      "iaas_type" : "ec2",
      "is_default_target": true,
      "iaas_properties" : {
        "region" : "<%= ec2_region %>"
      },
      "type": "staging",
      "*project_id": "/project/<%= project_ref %>"
    }
  }
}
eos

  def create_new_target?(target_name,ec2_region=nil)
    # TODO: this is hack that should be fixed up
    container_idh = pre_execute(:top)
    template_path ||= "#{Root}/spec/test_data/new_target.erb"
    template = File.open(template_path){|f|f.read}
    erubis = Erubis::Eruby.new(template)
    users_ref = "private-#{username}"
    json_content = erubis.result(:target_name => target_name,:project_ref => users_ref,:target_ref => target_name,:ec2_region => ec2_region||"us-east-1")
    hash_content = JSON.parse(json_content)
    Model.import_objects_from_hash(container_idh,hash_content)

    # return idhs of new targets
    {
      :target_idhs => ret_idhs("datacenter",hash_content,container_idh)
    }
  end

  def ret_idhs(mn,hash_content,container_idh)
    (hash_content[mn]||{}).keys.map do |key|
      ref = "/#{mn}/#{key}"
      container_idh.createIDH(:uri => ref, :model_name => mn.to_sym)
    end
  end
  private :ret_idhs

  def add_modules_workspaces(project,library_impls)
    library_impls.map{|library_impl|library_impl.clone_into_project_if_needed(project)}
  end

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

