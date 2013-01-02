module XYZ
  class Service_moduleController < AuthController
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

    def rest__list()
      project = get_default_project()
      rest_ok_response ServiceModule.list(model_handle, :project_idh => project.id_handle())
    end

    def rest__list_remote()
      rest_ok_response ServiceModule.list_remotes(model_handle)
    end

    def rest__import()
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name))
      remote_repo = (ret_request_params(:remote_repo)||Repo::Remote.default_remote_repo()).to_sym
      project = get_default_project()
      remote_params = {
        :repo => remote_repo,
        :namespace => remote_namespace,
        :module_name => remote_module_name,
        :version => version
      }
      local_params = {
        :module_name => remote_module_name #TODO: hard coded making local module name same as remote module_name
      }
      ServiceModule.import(project,remote_params,local_params)
      rest_ok_response
    end
    
    def rest__export()
      service_module = create_obj(:service_module_id)
      remote_repo = (ret_request_params(:remote_repo)||Repo::Remote.default_remote_repo()).to_sym
      service_module.export(remote_repo)
      rest_ok_response 
    end

    #either indicates no auth or sends back info needed to push changes to remote
    def rest__check_remote_auth()
      service_module = create_obj(:service_module_id)
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      remote_repo = (ret_request_params(:remote_repo)||Repo::Remote.default_remote_repo()).to_sym
      rest_ok_response service_module.check_remote_auth(remote_repo,rsa_pub_key,Repo::Remote::Auth::RW)
    end

    def rest__push_to_remote_legacy()
      service_module = create_obj(:service_module_id)
      service_module.push_to_remote__deprecate()
      rest_ok_response
    end
    
    def rest__list_assemblies()
      service_module_id = ret_request_param_id(:service_module_id)
      service_module = create_object_from_id(service_module_id)
      rest_ok_response service_module.list_assembly_templates()
    end

    def rest__get_workspace_branch_info()
      service_module = create_obj(:service_module_id)
      version = ret_request_params(:version)
      rest_ok_response service_module.get_workspace_branch_info(version)
    end

    def rest__create()
      module_name = ret_non_null_request_params(:module_name)
      config_agent_type =  ret_request_params(:config_agent_type)|| :puppet
      project = get_default_project()
      service_module_idh = ServiceModule.create_workspace_module_obj(project,module_name,config_agent_type)
      rest_ok_response(:service_module_id => service_module_idh.get_id())
    end
    
    def rest__delete()
      service_module_id = ret_request_param_id(:service_module_id)
      ServiceModule.delete(id_handle(service_module_id))
      rest_ok_response
    end

    def rest__delete_remote()
      name = ret_non_null_request_params(:remote_module_name)
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(name)
      remote_repo = (ret_request_params(:remote_repo)||Repo::Remote.default_remote_repo()).to_sym
      remote_params = {
        :repo => remote_repo,
        :module_name => remote_module_name,
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
      version = ret_request_params(:version)
      json_diffs = ret_request_params(:json_diffs)
      diffs_summary = Repo::Diffs::Summary.new(json_diffs && JSON.parse(json_diffs))
      service_module.update_model_from_clone_changes?(diffs_summary,version)
      rest_ok_response
    end

  end
end
