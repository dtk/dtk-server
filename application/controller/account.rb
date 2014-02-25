module DTK
  class AccountController < AuthController
  	def rest__set_password()
      password = ret_non_null_request_params(:new_password)
      user = CurrentSession.new.get_user_object()
      
      rest_ok_response user.update_password(password)
    end

    def rest__list_ssh_keys()
      username = ret_non_null_request_params(:username)
      model_handle = model_handle_with_private_group()
      rest_ok_response RepoUser.get_matching_repo_users(model_handle.createMH(:repo_user), {:type=>'client'}, username, ["username"])
    end

    # we use this method to add user access to modules / servier / repo manager
    def rest__add_user_direct_access
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      username = ret_request_params(:username)

      # Service call
      match_service, matched_username_service = ServiceModule.add_user_direct_access(model_handle_with_private_group(:service_module), rsa_pub_key, username)

      # Module call
      match_module, matched_username_module = ComponentModule.add_user_direct_access(model_handle_with_private_group(:component_module), rsa_pub_key, username)

      # Add Repo Manager user
      response = Repo::Remote.new.create_client_user(rsa_pub_key)

      # match is boolean to see if there has been natch
      match = match_service && match_module
      matched_username = matched_username_service || matched_username_module

      # only if user exists already
      Log.info("User ('#{matched_username}') exist with given PUB key, not able to create a user with username ('#{username}')") if match
      
      rest_ok_response(
        :repo_manager_fingerprint => RepoManager.repo_server_ssh_rsa_fingerprint(), 
        :repo_manager_dns => RepoManager.repo_server_dns(), 
        :match => match
      )
    end
  end
end