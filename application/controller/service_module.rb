module XYZ
  class Service_moduleController < Controller
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
      rest_ok_response ServiceModule.list(model_handle)
    end

    def rest__list_remote()
      rest_ok_response ServiceModule.list_remotes(model_handle)
    end

    def rest__import()
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name))
      library_id = ret_request_params(:library_id) 
      library_idh = (library_id && id_handle(library_id,:library)) || Library.get_public_library(model_handle(:library)).id_handle()
      unless library_idh
        raise Error.new("No library specified and no default can be determined")
      end
      ServiceModule.import(library_idh,remote_module_name,remote_namespace,version)
      rest_ok_response
    end
    
    def rest__export()
      service_module_id = ret_request_param_id(:service_module_id)
      service_module = create_object_from_id(service_module_id)
      service_module.export()
      rest_ok_response 
    end

    def rest__push_to_remote()
      service_module = create_obj(:service_module_id)
      service_module.push_to_remote()
      rest_ok_response
    end
    
    def rest__list_assemblies()
      service_module_id = ret_request_param_id(:service_module_id)
      service_module = create_object_from_id(service_module_id)
      rest_ok_response service_module.list_assembly_templates()
    end

    def rest__create_workspace_branch()
      service_module = create_obj(:service_module_id)
      version = ret_request_params(:version)
      project = get_default_project()
      workspace_branch_info = service_module.create_workspace_branch?(project,version)
      rest_ok_response workspace_branch_info
    end

    def rest__create()
      module_name = ret_non_null_request_params(:module_name)
      library_id = ret_request_params(:library_id) 
      library_idh = (library_id && id_handle(library_id,:library)) || Library.get_public_library(model_handle(:library)).id_handle()
      unless library_idh
        raise ErrorUsage.new("No library specified and no default can be determined")
      end
      config_agent_type =  ret_request_params(:config_agent_type)|| :puppet
      service_module_idh = ServiceModule.create_library_module_obj(library_idh,module_name,config_agent_type)
      rest_ok_response(:service_module_id => service_module_idh.get_id())
    end
    
    def rest__delete()
      service_module_id = ret_request_param_id(:service_module_id)
      ServiceModule.delete(id_handle(service_module_id))
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

     def rest__workspace_branch_info()
      service_module = create_obj(:service_module_id)
      version = ret_request_params(:version)
      workspace_branch_info = service_module.get_workspace_branch_info(version)
      rest_ok_response workspace_branch_info
    end

    def rest__deprecate_workspace_branch_info(service_module_id)
      #TODO: stub using library branch until put in service module workspace mechanism
      service_module = create_object_from_id(service_module_id)
      repo = service_module.get_library_repo()
      service_module_name = service_module.update_object!(:display_name)[:display_name] 
      workspace_branch_info = {
        :branch => "master", 
        :module_name => service_module_name,
        :repo_url => RepoManager.repo_url(repo[:repo_name])
      }
      rest_ok_response workspace_branch_info
    end
  end
end
