#!/usr/bin/env ruby
#general initial
require 'rubygems'
require 'optparse'
require File.expand_path('library_nodes', File.dirname(__FILE__))
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
#      import_file = "#{Root}/spec/test_data/library_node_data.json" #TODO: hack
#      Model.import_objects_from_file(container_idh,import_file)
       hash_content = LibraryNodes.get()
       Model.import_objects_from_hash(container_idh,hash_content)
    else
      library_mh = pre_execute(:library)
      Library.create_public_library?(library_mh)
    end
  end

  def create_public_library_assemblies(assemblies_hash,node_bindings_hash)
    library_mh = pre_execute(:library)
    library_idh = Library.create_public_library?(library_mh)
    Assembly.reify(library_idh,assemblies_hash,node_bindings_hash)
  end


  def create_users_private_library?()
    library_mh = pre_execute(:library)
    Library.create_users_private_library?(library_mh)
  end

  def create_users_private_target?(import_file=nil)
    #TODO: this is hack that should be fixed up
    container_idh = pre_execute(:top)
    template_path ||= "#{Root}/spec/test_data/target_data_template.erb" 
    template = File.open(template_path){|f|f.read}
    erubis = Erubis::Eruby.new(template)
    users_ref = "private-#{username}"
    json_content = erubis.result(:project_ref => users_ref,:target_ref => users_ref)
    hash_content = JSON.parse(json_content)
    Model.import_objects_from_hash(container_idh,hash_content)
  end

  def add_modules_from_external_repo_dir(*module_names)
    library_mh = pre_execute(:library)
    library_idh = Library.get_users_private_library(library_mh).id_handle()
    config_agent_type = :puppet
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
      impl_obj.add_library_files_from_directory(repo_obj)
    
      r8meta_path = "#{module_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash = YAML.load_file(r8meta_path)

      Model.add_library_components_from_r8meta(config_agent_type,library_idh,impl_obj.id_handle,r8meta_hash)
      
      impl_obj.add_contained_files_and_push_to_repo()
    end
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

