module XYZ
  class Repo < Model
    def self.get_all_repo_names(model_handle)
      get_objs(model_handle,:cols => [:repo_name]).map{|r|r[:repo_name]}
    end

    def self.create?(model_handle,module_name,config_agent_type,repo_user_acls)
      repo_name = repo_name(config_agent_type,module_name)
      repo_obj = create_repo_obj?(model_handle,repo_name)
      repo_obj.set_repo_user_acls(repo_user_acls)
      RepoManager.create_repo?(repo_obj,repo_user_acls) 
      repo_obj
    end

    def set_repo_user_acls(repo_user_acls)
      repo_id = id()
      #TODO: more efficient if RepoUser.get_by_username takes a list
      repo_user_mh = model_handle(:repo_user)
      unpruned_rows = repo_user_acls.map do |acl|
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

      sp_hash = {
        :cols => [:id,:repo_user_id],
        :filter => [:and, [:eq, :repo_id, repo_id], [:oneof, :repo_user_id, unpruned_rows.map{|r|r[:repo_user_id]}]]
      }
      existing_acls = Model.get_objs(model_handle(:repo_user_acl),sp_hash)
      if existing_acls.empty? #short circuit
        Model.create_from_rows(model_handle(:repo_user_acl),unpruned_rows)
      else
        #create ones that dont exist
        existing_repo_user_ids = existing_acls.map{|r|r[:repo_user_id]}
        rows = unpruned_rows.reject{|r|existing_repo_user_ids.include?(r[:repo_user_id])}
        Model.create_from_rows(model_handle(:repo_user_acl),rows) unless rows.empty?
        #delete ones that should not exist
        new_repo_user_ids = unpruned_rows.map{|r|r[:repo_user_id]}
        delete_idhs = existing_acls.reject{|r|new_repo_user_ids.include?(r[:repo_user_id])}.map{|r|model_handle.createIDH(:id => r[:id])}
        Model.delete_instances(delete_idhs) unless delete_idhs.empty?
      end
      nil
    end

   private    
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
    def self.repo_name(config_agent_type,module_name)
      username = CurrentSession.new.get_user_object()[:username]
      RepoManager.repo_name(username,config_agent_type,module_name)
    end
  end
end
