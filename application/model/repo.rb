module XYZ
  class Repo < Model
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def self.create?(model_handle,module_name,config_agent_type,repo_user_acls)
    end
   private
    def self.repo_name(config_agent_type,module_name)
      username = CurrentSession.new.get_user_object()[:username]
      RepoManager.repo_name(username,config_agent_type,module_name)
    end
  end
end
