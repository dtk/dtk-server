module DTK
  class Service_moduleController < AuthController
    helper :module_helper
    helper :component_template_helper
    
    #TODO: for debugging; will be removed
    def rest__debug_get_project_trees()
      ServiceModule.get_project_trees(model_handle)
      rest_ok_response
    end

    def rest__debug_get_ports(service_module_id)
      service_module = create_object_from_id(service_module_id)
      service_module.get_ports()
      rest_ok_response
    end
    #end: for debugging; will be removed

    #### actions to interact with remote repos ###
    def rest__list_remote()
      rest_ok_response ServiceModule.list_remotes(model_handle)
    end

    def rest__list_assemblies()
      service_module_id = ret_request_param_id(:service_module_id)
      service_module = create_obj(:service_module_id)
      rest_ok_response service_module.get_assembly_templates()
    end

    def rest__import()
      rest_ok_response import_method_helper(ServiceModule)
    end
    
    #this should be called when the module is linked, but the specfic version is not
    def rest__import_version()
      service_module = create_obj(:service_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response service_module.import_version(remote_repo,version)
    end

    def rest__export()
      service_module = create_obj(:service_module_id)
      remote_repo = ret_remote_repo()
      name_and_ns_params = ret_params_hash_with_nil(:remote_component_name, :remote_component_namespace)
      
      service_module.export(remote_repo, nil, name_and_ns_params)
      rest_ok_response 
    end

    #get remote_module_info; throws an access rights usage eerror if user does not have access
    def rest__get_remote_module_info()
      service_module = create_obj(:service_module_id)
      rsa_pub_key,action = ret_non_null_request_params(:rsa_pub_key,:action)
      access_rights = ret_access_rights()
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response service_module.get_remote_module_info(action,remote_repo,rsa_pub_key,access_rights,version)
    end

    #### end actions to interact with remote repos ###

    def rest__list()
      project = get_default_project()
      rest_ok_response ServiceModule.list(model_handle, :project_idh => project.id_handle())
    end

    def rest__info()
      module_id = ret_request_param_id_optional(:service_module_id, ::DTK::ServiceModule)
      rest_ok_response ServiceModule.info(model_handle(), module_id)
    end

    def rest__info_about()
      service_module = create_obj(:service_module_id)
      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum.include?(about)
        raise ErrorUsage::BadParamValue.new(:about,AboutEnum)
      end
      rest_ok_response service_module.info_about(about)
    end
    AboutEnum = ["assembly-templates".to_sym,:components]

    def rest__get_workspace_branch_info()
      service_module = create_obj(:service_module_id)
      version = ret_request_params(:version)
      rest_ok_response service_module.get_workspace_branch_info(version)
    end

    def rest__create()
      module_name = ret_non_null_request_params(:module_name)
      config_agent_type =  ret_config_agent_type()
      project = get_default_project()
      service_module_idh = ServiceModule.initialize_module(project,module_name,config_agent_type)[:module_idh]
      rest_ok_response(:service_module_id => service_module_idh.get_id())
    end

    def rest__create_new_version()
      service_module = create_obj(:service_module_id)
      version = ret_version()
      service_module.create_new_version(version)
      rest_ok_response
    end

    def rest__delete()
      service_module = create_obj(:service_module_id)
      module_info = service_module.delete_object()
      rest_ok_response module_info
    end

    def rest__delete_remote()
      name = ret_non_null_request_params(:remote_service_name)
      remote_namespace,remote_service_name,version = Repo::Remote::split_qualified_name(name)
      remote_repo = ret_remote_repo()
      remote_params = {
        :repo => remote_repo,
        :module_name => remote_service_name,
        :module_namespace => remote_namespace
      }
      remote_params.merge!(:version => version) if version
      project = get_default_project()
      ServiceModule.delete_remote(project,remote_params)
      rest_ok_response 
    end

    def rest__add_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ServiceModule.add_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response(:repo_manager_fingerprint => RepoManager.repo_server_ssh_rsa_fingerprint(), :repo_manager_dns => RepoManager.repo_server_dns())
    end

    def rest__remove_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ServiceModule.remove_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response
    end

    def rest__update_model_from_clone()
      service_module = create_obj(:service_module_id)
      commit_sha = ret_non_null_request_params(:commit_sha)
      version = ret_request_params(:version)
      diffs_summary = ret_diffs_summary()
      service_module.update_model_from_clone_changes?(commit_sha,diffs_summary,version)
      rest_ok_response 
    end

    def rest__set_component_module_version()
      service_module = create_obj(:service_module_id)
      component_module = create_obj(:component_module_id,ComponentModule)
      version = ret_version()
      clone_update_info = service_module.set_component_module_version(component_module,version)
      rest_ok_response clone_update_info
    end

  end
end
