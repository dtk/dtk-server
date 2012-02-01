module XYZ
  class RepoController < Controller
    def rest__delete()
      repo_id = ret_non_null_request_params(:repo_id)
      repo = create_object_from_id(repo_id)
      RepoManager.delete_repo(repo)
    end
  end
end
