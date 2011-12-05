module XYZ
  class RepoUserAcl < Model
    #TODO: see if can simplify and move into Repo using input_hash_content_into_model with nested hash
    def self.modify(repo_idh,repo_user_acls)
      repo_id = repo_idh.get_id()
      #TODO: more efficient if RepoUser.get_by_username takes a list
      repo_user_mh = repo_idh.createMH(:repo_user)
      rows = repo_user_acls.map do |acl|
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
      model_handle = repo_idh.create_childMH(:repo_user_acl)
      modify_children_from_rows(model_handle,repo_idh,rows)
    end
  end
end
