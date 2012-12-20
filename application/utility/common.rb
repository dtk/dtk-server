#!/usr/bin/env ruby
#general initial
require 'rubygems'
require 'optparse'
require 'sshkey'
require File.expand_path('library_nodes', File.dirname(__FILE__))
Root = File.expand_path('../', File.dirname(__FILE__))
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
      RepoUser.add_repo_user(:node,repo_user_mh,ssh_rsa_keys)
    end
  end

  def create_public_library?(opts={})
    #TODO: hack; must unify; right now based on assumption on name that appears in import file
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
    {
      :target_idhs => ret_idhs("datacenter",hash_content,container_idh), 
      :project_idhs => ret_idhs("project",hash_content,container_idh)
    }
  end

  #TODO: this is hack that should be fixed up; no need to use josn here
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
      "display_name": "Staging East1",
      "description": "Staging East1",
      "iaas_type" : "ec2",
      "is_default_target": true,
      "iaas_properties" : {
        "region" : "<%= ec2_region %>",
	"security_group_set" : ["default"]
      },     
      "type": "staging",
      "*project_id": "/project/<%= project_ref %>"
    }
  }
}
eos

  def create_new_target?(target_name,ec2_region=nil)
    #TODO: this is hack that should be fixed up
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

  def migrate_metafile(module_name)
    raise Error.new("Function has been deprecated")
=begin
#TODO: probably deprecate: it is also out of date so wil not work
    component_module_mh = pre_execute(:component_module)
    sp_hash = {
      :cols => [:id,:dispaly_name],
      :filter => [:eq,:display_name,module_name]
    }
    cm = Model.get_obj(component_module_mh,sp_hash)
    repos = cm.get_repos()
    unless repos.size == 1
      raise Error.new("Cannot find unique repo")
    end
    repo = repos.first

    impls = cm.get_library_implementations()
    unless impls.size == 1
      raise Error.new("Cannot find unique implementation")
    end
    impl = impls.first

    dsl = ComponentDSL.create_dsl_object_from_impl(impl)
    new_version_integer = 2 
    hash_content = DTK::ComponentDSL::migrate_processor(module_name,new_version_integer,dsl.input_hash).generate_new_version_hash()
    content = JSON.pretty_generate(hash_content)
    new_path = "dtk-meta.puppet.json"
    impl.add_file_and_push_to_repo(new_path,content,:is_meta_file => true)
    "#{repo[:local_dir]}/#{new_path}"
=end
  end


  def ret_idhs(mn,hash_content,container_idh)
    (hash_content[mn]||{}).keys.map do |key|
      ref = "/#{mn}/#{key}"
      container_idh.createIDH(:uri => ref, :model_name => mn.to_sym)
    end
  end
  private :ret_idhs

  def add_modules_from_external_repo_dir(module_names)
    library_mh = pre_execute(:library)
    library_idh = Library.get_users_private_library(library_mh).id_handle()
    config_agent_type = :puppet
    ret = Array.new
    module_names.each do |module_name|
      repo_obj,impl_obj = Implementation.create_library_repo_and_implementation(library_idh,module_name,config_agent_type, :delete_if_exists => true)
      module_dir = repo_obj[:local_dir]

      #copy files
      source_dir = "#{R8::EnvironmentConfig::SourceExternalRepoDir}/puppet/#{module_name}" 
      #TODO: more efficient to use copy pattern that does not include .git in first place
      FileUtils.cp_r "#{source_dir}/.", module_dir
      source_git = "#{source_dir}/.git"
      FileUtils.rm_rf source_git if File.directory?(source_git)
      
      #add file_assets
      impl_obj.create_file_assets_from_dir_els()
    
      r8meta_path = "#{module_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash = YAML.load_file(r8meta_path)

      ComponentDSL.add_components_from_r8meta(library_idh,config_agent_type,impl_obj.id_handle,r8meta_hash)
      
      impl_obj.add_contained_files_and_push_to_repo()
      ret << impl_obj
    end
    ret
  end

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

