module XYZ
  class Repo < Model
    ###virtual columns
    def base_dir()
      self[:local_dir].gsub(/\/[^\/]+$/,"")
    end
    ####
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def self.create(model_handle,module_name,config_agent_type,repo_user_acls,opts={})
      repo_name = repo_name(config_agent_type,module_name)
      repo_obj = create_repo_obj?(model_handle,repo_name)
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

   private    
    def self.repo_name(config_agent_type,module_name)
      username = CurrentSession.get_username()
      RepoManager.repo_name(username,config_agent_type,module_name)
    end

    def self.create_repo_obj?(model_handle,repo_name)
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
      repo_idh = create_from_row(model_handle,repo_hash)
      repo_id = repo_idh.get_id()
      repo_idh.create_object().merge(repo_hash)
    end

    def self.common_columns()
      [:id,:display_name,:repo_name,:local_dir]
    end
  end
end
