module XYZ
  class Repo < Model
    r8_nested_require('repo','remote')
    r8_nested_require('repo','diff')
    r8_nested_require('repo','diffs')

    ###virtual columns
    def base_dir()
      self[:local_dir].gsub(/\/[^\/]+$/,"")
    end
    ####
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def get_acesss_rights(repo_user_idh)
      sp_hash = {
        :cols => [:id,:group_id,:access_rights,:repo_usel_id,:repo_id],
        :filter => [:and, [:eq,:repo_id,id()],[:eq,:repo_user_id,repo_user_idh.get_id()]]
      }
      Model.get_obj(model_handle(:repo_user_acl),sp_hash)
    end

    def linked_remote?(remote_repo=nil)
      unless remote_repo.nil? or remote_repo == Repo::Remote.default_remote_repo()
        raise Error.new("Not implemented yet for remote's other than default")
      end
      update_object!(:remote_repo_name)[:remote_repo_name]
    end

    def self.create_empty_workspace_repo(project_idh,module_name,module_specific_type,repo_user_acls,opts={})
      #find repo name
      #MOD_RESTRUCT: TODO: may be heere decide whether do what is doing now where each user has own repo or we share repos accross server instance
      #(distinguishing using branches
      #for shared may use name generated by: repo_name = public_repo_name(module_name,module_specific_type)
      repo_name = private_user_repo_name(module_name,module_specific_type)

      extra_attrs = [:remote_repo_name,:remote_repo_namespace].inject(Hash.new) do |h,k|
        opts[k] ? h.merge(k => opts[k]) : h
      end

      repo_mh = project_idh.createMH(:repo)
      repo_obj = create_repo_obj?(repo_mh,repo_name,extra_attrs)
      repo_idh = repo_mh.createIDH(:id => repo_obj[:id])
      RepoUserAcl.modify_model(repo_idh,repo_user_acls)
      RepoManager.create_empty_workspace_repo(repo_obj,repo_user_acls,opts) 
      repo_obj
    end
    #MOD_RESTRUCT: TODO: deprecate below for above
    def self.create_empty_repo_and_local_clone(library_idh,module_name,module_specific_type,repo_user_acls,opts={})
      #find repo name
      public_lib = Library.get_public_library(library_idh.createMH())
      if (public_lib && public_lib[:id]) == library_idh.get_id()
        repo_name = public_repo_name(module_name,module_specific_type)
      else
        repo_name = private_user_repo_name(module_name,module_specific_type)
      end 

      extra_attrs = [:remote_repo_name,:remote_repo_namespace].inject(Hash.new) do |h,k|
        opts[k] ? h.merge(k => opts[k]) : h
      end

      repo_mh = library_idh.createMH(:repo)
      repo_obj = create_repo_obj?(repo_mh,repo_name,extra_attrs)
      repo_idh = repo_mh.createIDH(:id => repo_obj[:id])
      RepoUserAcl.modify_model(repo_idh,repo_user_acls)
      RepoManager.create_repo_and_local_clone(repo_obj,repo_user_acls,opts) 
      repo_obj
    end

    def update_for_new_repo(branches)
      update_object!(:repo_name)
      RepoManager.fetch_all(self)
      branches.each{|branch|RepoManager.rebase_from_remote(:repo_dir => self[:repo_name], :branch => branch)}
    end

    def self.delete(repo_idh)
      repo = repo_idh.create_object()
      RepoManager.delete_repo(repo)
      Model.delete_instance(repo_idh)
    end

    def diff_between_library_and_workspace(lib_branch,ws_branch)
      RepoManager.diff(ws_branch[:branch],lib_branch)
    end
    
    def initial_synchronize_with_remote_repo(remote_params,branch,opts={})
      unless R8::Config[:repo][:workspace][:use_local_clones]
        raise Error.new("Not implemented yet: initial_synchronize_with_remote_repo w/o local clones")
      end
      update_object!(:repo_name,:remote_repo_name)
      unless self[:remote_repo_name]
        raise ErrorUsage.new("Cannot synchronize with remote repo if local repo not linked")
      end
      remote_url = Remote.new(remote_params[:repo]).repo_url_ssh_access(self[:remote_repo_name])
      remote_name = remote_name_for_push_pull(remote_params[:repo])
      remote_branch = Remote.version_to_branch_name(remote_params[:version])
      repo_opts = opts.merge(:initial => true, :remote_branch => remote_branch)
      RepoManager.synchronize_with_remote_repo(self[:repo_name],branch,remote_name,remote_url,repo_opts)
    end
    #MOD_RESTRUCT: TODO: see if need below any more now that have above
    def synchronize_with_remote_repo(branch,opts={})
      update_object!(:repo_name,:remote_repo_name)
      unless self[:remote_repo_name]
        raise ErrorUsage.new("Cannot synchronize with remote repo if local repo not linked")
      end
      remote_url = Remote.new().repo_url_ssh_access(self[:remote_repo_name])
      remote_name = remote_name_for_push_pull()
      RepoManager.synchronize_with_remote_repo(self[:repo_name],branch,remote_name,remote_url,opts)
    end

    def ret_remote_merge_relationship(remote_repo,local_branch,version,opts={})
      update_object!(:repo_name)
      remote_name = remote_name_for_push_pull(remote_repo)
      remote_branch = Remote.version_to_branch_name(version)
      RepoManager.ret_remote_merge_relationship(self[:repo_name],local_branch,remote_name,opts.merge(:remote_branch => remote_branch))
    end

    def push_to_remote(branch,remote_repo_name,version=nil)
      unless remote_repo_name
        raise ErrorUsage.new("Cannot push to remote repo if local repo not linked")
      end
      update_object!(:repo_name)
      remote_name = remote_name_for_push_pull()
      remote_branch = Remote.version_to_branch_name(version)
      RepoManager.push_to_remote_repo(self[:repo_name],branch,remote_name,remote_branch)
    end

    def link_to_remote(branch,remote_repo_name)
      update_object!(:repo_name)
      remote_url = Remote.new.repo_url_ssh_access(remote_repo_name)
      remote_name = remote_name_for_push_pull()
      RepoManager.link_to_remote_repo(self[:repo_name],branch,remote_name,remote_url)
      remote_repo_name
    end

    def unlink_remote(remote_repo)
      update_object!(:repo_name)
      remote_name = remote_name_for_push_pull(remote_repo)
      RepoManager.unlink_remote(self[:repo_name],remote_name)
      update(:remote_repo_name => nil, :remote_repo_namespace => nil)
    end

   private    
    def remote_name_for_push_pull(remote_name=nil)
      remote_name||"remote"
    end

    def self.private_user_repo_name(module_name,module_specific_type)
      username = CurrentSession.new.get_username()
      incorporate_module_type(module_specific_type,"#{username}-#{module_name}")

    end
    def self.public_repo_name(module_name,module_specific_type)
      incorporate_module_type(module_specific_type,"public-#{module_name}")
    end

    def self.incorporate_module_type(module_specific_type,repo_name)
      #module_specfic_type can be :service_module, :puppet or :chef
      module_specific_type == :service_module ? "sm-#{repo_name}" : repo_name
    end

    def self.create_repo_obj?(model_handle,repo_name,extra_attrs={})
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq,:repo_name,repo_name]
      }
      ret = get_obj(model_handle,sp_hash)
      return ret if ret 

      repo_hash = {
        :ref => repo_name,
        :display_name => repo_name,
        :repo_name => repo_name,
        :local_dir =>  "#{R8::Config[:repo][:base_directory]}/#{repo_name}" #TODO: should this be set by RepoManager instead
      }
      repo_hash.merge!(extra_attrs)

      repo_idh = create_from_row(model_handle,repo_hash)
      repo_id = repo_idh.get_id()
      repo_idh.create_object().merge(repo_hash)
    end

    def self.common_columns()
      [:id,:display_name,:repo_name,:local_dir]
    end
  end
end
