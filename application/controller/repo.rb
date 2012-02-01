module XYZ
  class RepoController < Controller
    def rest__delete()
      repo_id = ret_non_null_request_params(:repo_id)
      Repo.delete(id_handle(repo_id))
      rest_ok_response
    end
  end
end
