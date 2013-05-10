module DTK
  class Component_moduleController < AuthController
    helper :module_helper

    def rest__test_generate_dsl()
      component_module = create_obj(:component_module_id)
      dsl_created_info = component_module.test_generate_dsl()
      STDOUT << dsl_created_info[:content] << "\n"
      rest_ok_response
    end

      #### create and delete actions ###
    def rest__create()
      module_name = ret_non_null_request_params(:module_name)
      config_agent_type =  ret_config_agent_type()
      project = get_default_project()
      version = nil
      module_repo_info = ComponentModule.initialize_module(project,module_name,config_agent_type,version)[:module_repo_info]
      rest_ok_response module_repo_info
    end

    def rest__update_from_initial_create()
      component_module = create_obj(:component_module_id)
      repo_id,commit_sha = ret_non_null_request_params(:repo_id,:commit_sha)
      repo_idh = id_handle(repo_id,:repo)
      version = ret_version()
      scaffold = ret_request_params(:scaffold_if_no_dsl)
      opts = {:scaffold_if_no_dsl => scaffold}
      dsl_created_info = component_module.update_from_initial_create(commit_sha,repo_idh,version,opts)
      rest_ok_response dsl_created_info
    end

    def rest__update_model_from_clone()
      component_module = create_obj(:component_module_id)
      commit_sha = ret_non_null_request_params(:commit_sha)
      version = ret_version()
      diffs_summary = ret_diffs_summary()
      dsl_created_info = component_module.update_model_from_clone_changes?(commit_sha,diffs_summary,version)
      rest_ok_response dsl_created_info
    end

    def rest__delete()
      component_module = create_obj(:component_module_id)
      module_info = component_module.delete_object()
      rest_ok_response module_info
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list()
      project = get_default_project()
      rest_ok_response ComponentModule.list(model_handle, :project_idh => project.id_handle())
    end

    def rest__get_workspace_branch_info()
      component_module = create_obj(:component_module_id)
      version = ret_version()
      rest_ok_response component_module.get_workspace_branch_info(version)
    end

    def rest__get_all_workspace_library_diffs()
      rest_ok_response ComponentModule.get_all_workspace_library_diffs(model_handle)
    end

    def rest__info()
      module_id = ret_request_param_id_optional(:component_module_id, ::DTK::ComponentModule)
      rest_ok_response ComponentModule.info(model_handle(), module_id)
    end

    def rest__info_about()
      component_module = create_obj(:component_module_id)
      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum.include?(about)
        raise ErrorUsage::BadParamValue.new(:about,AboutEnum)
      end
      rest_ok_response component_module.info_about(about)
    end
    AboutEnum = [:components]

    #### end: list and info actions ###
    
    #### actions to interact with remote repos ###
    def rest__import()
      rest_ok_response import_method_helper(ComponentModule)
    end

    #this should be called when the module is linked, but the specfic version is not
    def rest__import_version()
      component_module = create_obj(:component_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response component_module.import_version(remote_repo,version)
    end

    def rest__delete_remote()
      name      = ret_non_null_request_params(:remote_module_name)
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(name)
      # use default one, if there is namaspace provided in request
      remote_namespace = ret_request_params(:remote_module_namespace) || remote_namespace
      remote_repo = ret_remote_repo()
      remote_params = {
        :repo => remote_repo,
        :module_name => remote_module_name,
        :module_namespace => remote_namespace
      }
      remote_params.merge!(:version => version) if version
      project = get_default_project()
      ComponentModule.delete_remote(project,remote_params)
      rest_ok_response 
    end

    def rest__list_remote()
      rest_ok_response ComponentModule.list_remotes(model_handle)
    end

    def rest__export()
      component_module = create_obj(:component_module_id)
      name_and_ns_params = ret_params_hash_with_nil(:remote_component_name, :remote_component_namespace)
      remote_repo = ret_remote_repo()
      component_module.export(remote_repo, nil, name_and_ns_params)
      rest_ok_response 
    end

    # get remote_module_info; throws an access rights usage error if user does not have access
    def rest__get_remote_module_info()
      component_module = create_obj(:component_module_id)
      rsa_pub_key,action = ret_non_null_request_params(:rsa_pub_key,:action)
      access_rights = ret_access_rights()
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response component_module.get_remote_module_info(action,remote_repo,rsa_pub_key,access_rights,version)
    end

    #### end: actions to interact with remote repo ###

    #### actions to manage workspace

    def rest__create_new_version()
      component_module = create_obj(:component_module_id)
      version = ret_version()
      component_module.create_new_version(version)
      rest_ok_response
    end

    def rest__create_new_dsl_version()
      component_module = create_obj(:component_module_id)
      dsl_version = ret_non_null_request_params(:dsl_version).to_i
      module_version = ret_version() 
      format = :json
      component_module.create_new_dsl_version(dsl_version,format,module_version)
      rest_ok_response 
    end

    #### end: actions to manage workspace and promote changes from workspace to library ###

    def rest__push_to_mirror()
      component_module = create_obj(:component_module_id)
      mirror_host = ret_non_null_request_params(:mirror_host)
      component_module.push_to_mirror(mirror_host)
    end

    def rest__add_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.add_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response(:repo_manager_fingerprint => RepoManager.repo_server_ssh_rsa_fingerprint(), :repo_manager_dns => RepoManager.repo_server_dns())
    end

    def rest__remove_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.remove_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response
    end
  end
end
