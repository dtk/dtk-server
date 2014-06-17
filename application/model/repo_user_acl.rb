module XYZ
  class RepoUserAcl < Model
    def self.update_model(repo,repo_user,new_access_rights)
      existing = repo.get_acesss_rights(repo_user.id_handle())
      if existing
        return if existing[:access_rights] == new_access_rights
        update_row = {
          :id => existing[:id],
          :access_rights => new_access_rights
        }
        update_from_rows(repo.model_handle(:repo_user_acl),[update_row])
      else
        repo_user.update_object!(:username)
        create_row = ret_create_hash(repo_user[:username],repo[:id],repo_user[:id],new_access_rights)
        create_from_row(repo.model_handle(:repo_user_acl),create_row)
      end
    end

    # TODO: see if can simplify and move into Repo using input_hash_content_into_model with nested hash
    def self.modify_model(repo_idh,repo_user_acls)
      repo_id = repo_idh.get_id()
      # TODO: more efficient if RepoUser.get_by_repo_username takes a list
      repo_user_mh = repo_idh.createMH(:repo_user)
      rows = repo_user_acls.map do |acl|
        repo_username = acl[:repo_username]
        unless repo_user_obj = RepoUser.get_by_repo_username(repo_user_mh,repo_username)
          raise Error.new("Unknown repo user (#{repo_username})")
        end
        ret_create_hash(repo_username, repo_id,repo_user_obj[:id],acl[:access_rights])
      end
      model_handle = repo_idh.create_childMH(:repo_user_acl)
      modify_children_from_rows(model_handle,repo_idh,rows)
    end

    private
    def self.ret_create_hash(repo_username,repo_id,repo_user_id,access_rights)
      {
        :ref => repo_username,
        :display_name => repo_username,
        :repo_id => repo_id,
        :repo_user_id => repo_user_id,
        :access_rights => access_rights
      }
    end
  end
end
