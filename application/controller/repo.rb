module XYZ
  class RepoController < Controller
    def rest__delete()
      repo_id = ret_non_null_request_params(:repo_id)
      Repo.delete(id_handle(repo_id))
      rest_ok_response
    end

    # TODO: using maybe just temporarily to import when adding files
    def rest__synchronize_target_repo()
      # TODO: check that refrershing all appropriate  implemnations by just using project_project_id is not null test 
      repo_id = ret_non_null_request_params(:repo_id)
      repo = create_object_from_id(repo_id)
      sp_hash = {
        :cols => [:id, :group_id, :display_name, :local_dir],
        :filter => [:and, [:eq, :repo_id, repo_id], [:neq, :project_project_id, nil]]
      }
      impls = Model.get_objs(model_handle(:implementation),sp_hash)
      raise Error.new("Expecting to just find one matching implementation") unless impls.size == 1
      impl = impls.first
      impl.create_file_assets_from_dir_els()
      impl.add_contained_files_and_push_to_repo()
      rest_ok_response
    end
  end
end
