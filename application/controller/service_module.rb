module DTK
  class Service_moduleController < AuthController
    helper :module_helper
    helper :component_template_helper
    helper :version_helper
    
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
      remote_repo = ret_remote_repo()
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
      remote_repo = ret_remote_repo()
      service_module.export(remote_repo)
      rest_ok_response 
    end

    #get remote_module_info; throws an access rights usage eerror if user does not have access
    def rest__get_remote_module_info()
      service_module = create_obj(:service_module_id)
      rsa_pub_key,action = ret_non_null_request_params(:rsa_pub_key,:action)
      remote_repo = ret_remote_repo()
      access_rights = ret_access_rights()
      rest_ok_response service_module.get_remote_module_info(action,remote_repo,rsa_pub_key,access_rights)
    end

    def rest__pull_from_remote()
      service_module = create_obj(:service_module_id)
      remote_repo = ret_remote_repo()
      service_module.pull_from_remote_if_fast_foward(remote_repo)
    end

    def rest__push_to_remote_legacy()
      service_module = create_obj(:service_module_id)
      service_module.push_to_remote__deprecate()
      rest_ok_response
    end
    
    def rest__info_about()
      service_module = create_obj(:service_module_id)
      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum.include?(about)
        raise ErrorUsage::BadParamValue.new(:about,AboutEnum)
      end
      rest_ok_response service_module.info_about(about)
    end
    AboutEnum = [:assemblies,:components]

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
      remote_repo = ret_remote_repo()
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

    def rest__create_component_version()
      service_module = create_obj(:service_module_id)
      component_template_idh = nil
      begin
        component_template_idh = ret_component_template_idh(:omit_version => true)
       rescue ErrorNameDoesNotExist => e
        service_name = service_module.update_object!(:display_name)[:display_name]
        raise e.qualify("for service with name (#{service_name})")
      end
      version, level = ret_request_params(:version,:level)
      if version
        raise ErrorUsage.new("Either version or level must be given, not both") if level
        raise_error_if_version_illegal_format(version)
        service_module.create_component_version__given_version(component_template_idh,version)
      else
        raise ErrorUsage.new("Either version or level must be given") unless level
        service_module.create_component_version__given_level(component_template_idh,level)
      end
      rest_ok_response
    end

    def rest__set_component_version()
      service_module = create_obj(:service_module_id)
      component_template_idh = nil
      begin
        component_template_idh = ret_component_template_idh()
       rescue ErrorNameDoesNotExist => e
        service_name = service_module.update_object!(:display_name)[:display_name]
        raise e.qualify("for service with name (#{service_name})")
      end
      version = ret_non_null_request_params(:version)
      raise_error_if_version_illegal_format(version)
      service_module.set_component_version(component_template_idh,version)
      rest_ok_response
    end

  end
end
