module DTK
  module ServiceOrComponentModuleClassMixin
    def create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,module_type,opts={})
      auth_repo_users = RepoUser.authorized_users(library_idh.createMH(:repo_user))
      repo_user_acls = auth_repo_users.map do |repo_username|
        {
          :repo_username => repo_username,
          :access_rights => "RW+"
        }
      end
      Repo.create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,repo_user_acls,module_type,opts)
    end

   private
    def remote_already_imported?(library_idh,remote_module_name)
      ret = nil
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :remote_repo, remote_module_name]]
      }
      cms = get_objs(library_idh.createMH(model_name),sp_hash)
      not cms.empty?
    end

    def conflicts_with_library_module?(library_idh,module_name)
      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:and, [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :display_name, module_name]]
      }
      cms = get_objs(library_idh.createMH(model_name),sp_hash)
      not cms.empty?
    end
  end
end
