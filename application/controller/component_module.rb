module XYZ
  class Component_moduleController < Controller
    helper :module_helper

    #### create and delete actions ###
    def create_empty_repo()
      module_name = ret_non_null_request_params(:component_module_name)
      library_idh = ret_library_idh_or_default()
      project = get_default_project()
      module_repo_info = ComponentModule.create_empty_repo(library_idh,project,module_name)
      rest_ok_response module_repo_info
    end

    def update_repo_and_add_meta_data()
      repo_id,library_id,module_name =  ret_non_null_request_params(:repo_id,:library_id,:module_name)
      ComponentModule.update_repo_and_add_meta_data(id_handle(repo_id,:repo),id_handle(library_id,:library),module_name)
      rest_ok_response
    end

    def rest__delete()
      component_module_id = ret_request_param_id(:component_module_id)
      ComponentModule.delete(id_handle(component_module_id))
      rest_ok_response
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list()
      rest_ok_response ComponentModule.list(model_handle)
    end

    def rest__list_remote()
      rest_ok_response ComponentModule.list_remotes(model_handle)
    end

    def rest__workspace_branch_info()
      component_module = create_obj(:component_module_id)
      version = ret_request_params(:version)
      workspace_branch_info = component_module.get_workspace_branch_info(version)
      rest_ok_response workspace_branch_info
    end
    #### end: list and info actions ###
    
    #### actions to interact with remote repo ###
    def rest__import()
      library_idh = ret_library_idh_or_default()
      ret_non_null_request_params(:remote_module_names).each do |name|
        remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(name)
        ComponentModule.import(library_idh,remote_module_name,remote_namespace,version)
      end
      rest_ok_response
    end

    def rest__export()
      component_module = create_obj(:component_module_id)
      component_module.export()
      rest_ok_response 
    end

    def rest__push_to_remote()
      component_module = create_obj(:component_module_id)
      component_module.push_to_remote()
      rest_ok_response
    end

    #### end: actions to interact with remote repo ###

    #### actions to manage workspace and promote changes from workspace to library ###
    def rest__promote_to_library()
      component_module = create_obj(:component_module_id)
      version = ret_request_params(:version)
      component_module.promote_to_library(version)
      rest_ok_response
    end

    def rest__promote_as_new_version()
      component_module = create_obj(:component_module_id)
      new_version = ret_non_null_request_params(:new_version)
      existing_version = ret_request_params(:existing_version)
      component_module.create_new_version(new_version,existing_version)
      rest_ok_response
    end

    def rest__create_workspace_branch()
      component_module = create_obj(:component_module_id)
      version = ret_request_params(:version)
      project = get_default_project()
      workspace_branch_info = component_module.create_workspace_branch?(project,version)
      rest_ok_response workspace_branch_info
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
      rest_ok_response(:repo_manager_footprint => RepoManager.footprint(), :repo_manager_dns => RepoManager.repo_server_dns())
    end

    def rest__remove_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.remove_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response
    end
  end
end
