module XYZ
  class RepoUserAcl < Model
    #TODO: see if can simplify and move into Repo using input_hash_content_into_model with nested hash
    def self.modify(repo_idh,repo_user_acls)
      repo_id = repo_idh.get_id()
      #TODO: more efficient if RepoUser.get_by_username takes a list
      repo_user_mh = repo_idh.createMH(:repo_user)
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

      model_handle = repo_idh.create_childMH(:repo_user_acl)

      existing_acls = get_objs(model_handle,sp_hash)
      if existing_acls.empty? #short circuit
        create_from_rows(model_handle,unpruned_rows)
      else
        #create ones that dont exist
        existing_repo_user_ids = existing_acls.map{|r|r[:repo_user_id]}
        rows = unpruned_rows.reject{|r|existing_repo_user_ids.include?(r[:repo_user_id])}
        create_from_rows(model_handle,rows) unless rows.empty?
        #delete ones that should not exist
        new_repo_user_ids = unpruned_rows.map{|r|r[:repo_user_id]}
        delete_idhs = existing_acls.reject{|r|new_repo_user_ids.include?(r[:repo_user_id])}.map{|r|model_handle.createIDH(:id => r[:id])}
        delete_instances(delete_idhs) unless delete_idhs.empty?
      end
      nil
    end
  end
end
