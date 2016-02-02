module DTK
  class AccountController < AuthController
    PUB_KEY_NAME_REGEX = /[a-zA-Z0-9_\-]*/

    def rest__set_password
      password = ret_non_null_request_params(:new_password)
      user = CurrentSession.new.get_user_object()

      rest_ok_response user.update_password(password)
    end

    def rest__list_ssh_keys
      username = ret_non_null_request_params(:username)
      model_handle = model_handle_with_private_group()
      # results = RepoUser.get_matching_repo_users(model_handle.createMH(:repo_user), { type: 'client' }, username, ['username'])
      repo_keys = CurrentSession.new.user_object.public_keys
      # we send current catalog user info in list ssh key table
      rest_ok_response repo_keys.each { |ssh_key_obj|  ssh_key_obj.merge!(:current_catalog_username => CurrentSession.catalog_username) if ssh_key_obj.has_repoman_direct_access? }
    end

    # we use this method to add user access to modules / servier / repo manager
    def rest__add_user_direct_access
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      is_first_registration = ret_request_param_boolean(:first_registration)
      # username in this context is rsa pub key name
      username = ret_request_params(:username)

      # also a flag to see if there were any errors
      repoman_registration_error = nil

      # we check if name is taken (this is mostly for default dtk-client name/username)
      if is_first_registration
        found_user = RepoUser.get_by_repo_username(model_handle(:repo_user), username)
        username = "#{username}-01" if found_user

        loop do
          break unless RepoUser.get_by_repo_username(model_handle(:repo_user), username)
          username = username.succ
        end

      end

      if username && !username.eql?(username.match(PUB_KEY_NAME_REGEX)[0])
        fail DTK::Error, "Invalid format of pub key name, characters allower are: '#{PUB_KEY_NAME_REGEX.source.gsub('\\', '')}'"
      end

      # we do this check in add user direct as well but for simplicity we will duplicate it here as well
      if RepoUser.find_by_pub_key(model_handle_with_private_group(), rsa_pub_key)
        fail ErrorUsage, RepoUser::SSH_KEY_EXISTS
      end

      begin
        # Add Repo Manager user
        response = Repo::Remote.new.add_client_access(rsa_pub_key, username)
      rescue DTK::Error => e
        # we conditionally ignore it and we fix it later when calling repomanager
        Log.warn("We were not able to add user to Repo Manager, reason: #{e.message}")

        # this is terrible practice but error/response classes are so tightly coupled to rest of the code
        # that I do not dare change them
        if e.message.include?('Name has already been taken')
          raise ErrorUsage, 'Please choose a different name for your key, name has been taken'
        end

        repoman_registration_error   = e.message
      end

      # Service call
      match_service, repo_user_service = ServiceModule.add_user_direct_access(model_handle_with_private_group(:service_module), rsa_pub_key, username)

      # Module call
      match_module, repo_user_module = ComponentModule.add_user_direct_access(model_handle_with_private_group(:component_module), rsa_pub_key, username)

      # match is boolean to see if there has been natch
      match = match_service && match_module
      matched_repo_user = repo_user_service || repo_user_module

      # set a flag in database if this user has been registered to repoman
      matched_repo_user.update(repo_manager_direct_access: true) if repoman_registration_error.nil?

      # only if user exists already
      Log.info("User ('#{matched_repo_user[:username]}') exists with given PUB key, not able to create a user. ") if match

      rest_ok_response(
        repo_manager_fingerprint: RepoManager.repo_server_ssh_rsa_fingerprint(),
        repo_manager_dns: RepoManager.repo_server_dns(),
        match: match,
        new_username: matched_repo_user ? matched_repo_user[:username] : nil,
        matched_username: match && matched_repo_user ? matched_repo_user[:username] : nil,
        repoman_registration_error: repoman_registration_error
      )
    end

    def rest__remove_user_direct_access
      username = ret_non_null_request_params(:username)
      repoman_registration_error = nil

      # if id instead of username
      if username.to_s =~ /^[0-9]+$/
        model_handle = model_handle_with_private_group()
        user_mh = model_handle.createMH(:repo_user)
        user = User.get_user_by_id(user_mh, username)
        username = user[:username] if user
      end

      begin
        response = Repo::Remote.new.remove_client_access(username)
      rescue DTK::Error => e
        # we ignore it and we fix it later when calling repomanager
        Log.warn("We were not able to remove user from Repo Manager, reason: #{e.message}")
        repoman_registration_error = e.message
      end

      ServiceModule.remove_user_direct_access(model_handle_with_private_group(:service_module), username)
      ComponentModule.remove_user_direct_access(model_handle_with_private_group(:component_module), username)

      rest_ok_response(
          repoman_registration_error: repoman_registration_error
      )
    end

    def rest__set_default_namespace
      namespace = ret_non_null_request_params(:namespace)

      user_object = CurrentSession.new.get_user_object()
      user_object.update(default_namespace: namespace)
      CurrentSession.new.set_user_object(user_object)

      rest_ok_response
    end

    def rest__check_catalog_credentials
      rest_ok_response(
        catalog_credentials_set: CurrentSession.are_catalog_credentials_seeded?
      )
    end

    def rest__set_catalog_credentials
      username, password = ret_non_null_request_params(:username, :password)
      validate = ret_request_param_boolean(:validate)
      user_object    = CurrentSession.new.get_user_object()
      is_public_user = CurrentSession.is_remote_public_user?

      # bellow method will throw error in case credentials are not valid
      password =  DataEncryption.hash_it(password)
      Repo::Remote.new.validate_catalog_credentials(username, password) if validate

      # we update user with new credentials
      user_object.update(catalog_username: username, catalog_password: password)
      session_obj = CurrentSession.new
      session_obj.set_user_object(user_object)
      # we invalidate the session for repoman
      session_obj.set_repoman_session_id(nil)

      # if user is public we "hijack" existing public keys
      # if is_public_user
      user_object.public_keys.each do |repo_user|
        begin
          # Add Repo Manager user
          response = Repo::Remote.new.add_client_access(repo_user[:ssh_rsa_pub_key], repo_user[:display_name], true)
        rescue DTK::Error => e
          # we conditionally ignore it and we fix it later when calling repomanager
          Log.warn("We were not able to hijack public key via Repo Manager, reason: #{e.message}")
        end
      end


      rest_ok_response
    end

    def rest__register_catalog_account
      username, password, email = ret_non_null_request_params(:username, :password, :email)
      first_name, last_name, activate_account = ret_request_params(:first_name, :last_name, :activate_account)

      response = Repo::Remote.new.register_catalog_user(username, email, password, first_name, last_name)

      rest_ok_response
    end


  end
end
