module XYZ
  class Repo < Model
    r8_nested_require('repo','remote')

    ###virtual columns
    def base_dir()
      self[:local_dir].gsub(/\/[^\/]+$/,"")
    end
    ####
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def self.create_empty_repo(model_handle,module_name,config_agent_type,repo_user_acls,opts={})
      repo_name = repo_name(config_agent_type,module_name)

      extra_attrs = Hash.new
      if opts[:remote_repo_name]
        extra_attrs.merge!(:remote_repo_name => opts[:remote_repo_name])
      end

      repo_obj = create_repo_obj?(model_handle,repo_name,extra_attrs)
      repo_idh = model_handle.createIDH(:id => repo_obj[:id])
      RepoUserAcl.modify(repo_idh,repo_user_acls)
      RepoManager.create_repo(repo_obj,repo_user_acls,opts) 
      repo_obj
    end

    def self.delete(repo_idh)
      repo = repo_idh.create_object()
      RepoManager.delete_repo(repo)
      Model.delete_instance(repo_idh)
    end

    def synchronize_with_remote_repo()
      update_object!(:repo_name,:remote_repo_name)
      remote_url = Remote.repo_url_ssh_access(self[:remote_repo_name])
      remote_name = "remote"
      context = {:implementation => {:repo => self[:repo_name], :branch => "master"}}
      RepoManager.add_remote(remote_name,remote_url,context)
      RepoManager.pull_changes(remote_name,context)
      self[:remote_repo_name]
    end

   private    
    def self.repo_name(config_agent_type,module_name)
      username = CurrentSession.get_username()
      RepoManager.repo_name(username,config_agent_type,module_name)
    end

    def self.create_repo_obj?(model_handle,repo_name,extra_attrs={})
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq,:repo_name,repo_name]
      }
      ret = get_obj(model_handle,sp_hash)
      if ret
        unless extra_attrs.empty?
          Log.info("TODO: does not check whether has changed #{extra_attrs.inspect}")
        end
        return ret 
      end
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
