module DTK
  class AccountController < AuthController
  	def rest__set_password()
      password = ret_non_null_request_params(:new_password)
      user = CurrentSession.new.get_user_object()
      
      user.update_password(password)
      rest_ok_response
    end

    def rest__list_ssh_keys()
      username = ret_non_null_request_params(:username)
      model_handle = model_handle_with_private_group()
      rest_ok_response RepoUser.get_matching_repo_users(model_handle.createMH(:repo_user), {:type=>'client'}, username, ["username"])
    end

  end
end