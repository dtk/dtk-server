module XYZ
  class Repo < Model
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def self.create?(model_handle,module_name,config_agent_type,repo_user_acls)
      repo_name = repo_name(config_agent_type,module_name)
      sp_hash = {
        :cols => common_columns(),
        :filter => [:eq,:repo_name,repo_name]
      }
      get_obj(model_handle,sp_hash) || create(model_handle,module_name,config_agent_type,repo_user_acls,repo_name)
    end
    
    def self.create(model_handle,module_name,config_agent_type,repo_user_acls,repo_name=nil)
      repo_name ||= repo_name(config_agent_type,module_name)
      repo_hash = {
        :ref => repo_name,
        :display_name => repo_name,
        :repo_name => repo_name,
        :local_dir =>   "#{R8::Config[:repo][:base_directory]}/#{repo_name}" #TODO: should this be set by RepoManager instead
      }
      repo_idh = create_from_row(model_handle,repo_hash)
      repo_id = repo_idh.get_id()
      repo_obj = repo_idh.create_object().merge(repo_hash)
      repo_user_mh = model_handle.createMH(:repo_user)
      repo_user_acl_rows = repo_user_acls.map do |acl|
        repo_username = acl[:repo_username]
        unless repo_user_obj = RepoUser.get_by_username(repo_user_mh,repo_username)
          raise Error.new("Unknown repo user (#{repo_username})")
        end
        {
          :ref => repo_username,
          :display_name => repo_username,
          :repo_id => repo_id,
          :repo_user_id => repo_user_obj[:id],
          :access_rights => acl[:access_rights]
        }
      end
      create_from_rows(model_handle.createMH(:repo_user_acl),repo_user_acl_rows)
      RepoManager.create_repo?(repo_obj,repo_user_acls) #using '?' form for resilency
      ret
    end
   private
    def self.common_columns()
      [:id,:display_name,:repo_name,:local_dir]
    end
    def self.repo_name(config_agent_type,module_name)
      username = CurrentSession.new.get_user_object()[:username]
      RepoManager.repo_name(username,config_agent_type,module_name)
    end
  end
end
