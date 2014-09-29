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
      rest_ok_response RepoUser.get_matching_repo_users(model_handle.createMH(:repo_user), {:type => 'client'}, username, ["username"])
    end

    # we use this method to add user access to modules / servier / repo manager
    def rest__add_user_direct_access
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      username = ret_request_params(:username)

      # Service call
      match_service, repo_user_service = ServiceModule.add_user_direct_access(model_handle_with_private_group(:service_module), rsa_pub_key, username)

      # Module call
      match_module, repo_user_module = ComponentModule.add_user_direct_access(model_handle_with_private_group(:component_module), rsa_pub_key, username)

      # match is boolean to see if there has been natch
      match = match_service && match_module
      matched_repo_user = repo_user_service || repo_user_module

      if matched_repo_user && !matched_repo_user.has_repoman_direct_access?
        begin
          # Add Repo Manager user
          response = Repo::Remote.new.add_client_access(rsa_pub_key)

          # update user so we know that rsa pub key was added
          matched_repo_user.update(:repo_manager_direct_access => true)
        rescue DTK::Error => e
          # we ignore it and we fix it later when calling repomanager
          Log.info("We were not able to add user to Repo Manager, reason: #{e.message}")
        end
      end

      # only if user exists already
      Log.info("User ('#{matched_repo_user[:username]}') exists with given PUB key, not able to create a user. ") if match

      rest_ok_response(
        :repo_manager_fingerprint => RepoManager.repo_server_ssh_rsa_fingerprint(),
        :repo_manager_dns => RepoManager.repo_server_dns(),
        :match => match,
        :new_username => matched_repo_user ? matched_repo_user[:username] : nil,
        :matched_username => match && matched_repo_user ? matched_repo_user[:username] : nil
      )
    end

    def rest__remove_user_direct_access()
      username = ret_non_null_request_params(:username)

      # if id instead of username
      if username.to_s =~ /^[0-9]+$/
        model_handle = model_handle_with_private_group()
        user_mh = model_handle.createMH(:repo_user)
        user = User.get_user_by_id( user_mh, username)
        username = user[:username] if user
      end

      response = Repo::Remote.new.remove_client_access(username)

      ServiceModule.remove_user_direct_access(model_handle_with_private_group(:service_module),username)
      ComponentModule.remove_user_direct_access(model_handle_with_private_group(:component_module),username)

      rest_ok_response
    end

    def rest__set_default_namespace()
      namespace = ret_non_null_request_params(:namespace)

      user_object = CurrentSession.new.get_user_object()
      user_object.update(:default_namespace => namespace)
      CurrentSession.new.set_user_object(user_object)

      rest_ok_response
    end
  end
end