module XYZ
  class Component_moduleController < Controller
    def rest__list()
      rest_ok_response ComponentModule.list(model_handle)
    end

    def rest__list_remote()
      rest_ok_response ComponentModule.list_remotes(model_handle)
    end

    def rest__import()
      library_id = ret_request_params(:library_id) 
      library_idh = (library_id && id_handle(library_id,:library)) || Library.get_public_library(model_handle(:library)).id_handle()
      unless library_idh
        raise Error.new("No library specified and no default can be determined")
      end
      ret_non_null_request_params(:remote_module_names).each do |name|
        remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(name)
        ComponentModule.import(library_idh,remote_module_name,remote_namespace,version)
      end
      rest_ok_response
    end

    def rest__export()
      component_module_id = ret_request_param_id(:component_module_id)
      component_module = create_object_from_id(component_module_id)
      component_module.export()
      rest_ok_response 
    end

    def rest__promote_to_library()
      component_module = create_obj(:component_module_id)
      new_version = ret_request_params(:new_version)
      component_module.promote_to_library(new_version)
      rest_ok_response
    end

    def rest__push_to_remote()
      component_module_id = ret_request_param_id(:component_module_id)
      component_module = create_object_from_id(component_module_id)
      component_module.push_to_remote()
      rest_ok_response
    end

    def rest__push_to_mirror()
      component_module_id = ret_request_param_id(:component_module_id)
      mirror_host = ret_non_null_request_params(:mirror_host)
      component_module = create_object_from_id(component_module_id)
      component_module.push_to_mirror(mirror_host)
    end

    def rest__update_library()
      component_module_id = ret_request_param_id(:component_module_id)
      component_module = create_object_from_id(component_module_id)
      component_module.update_library_module_with_workspace()
      rest_ok_response
    end

    def rest__delete()
      component_module_id = ret_request_param_id(:component_module_id)
      ComponentModule.delete(id_handle(component_module_id))
      rest_ok_response
    end

    def rest__add_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.add_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response(:repo_manager_footprint => RepoManager.footprint(), :repo_manager_dns => RepoManager.repo_server_dns())
    end

    def rest__workspace_branch_info(component_module_id)
      component_module = create_object_from_id(component_module_id)
      ws_branch_info = component_module.get_workspace_branch_info()
      workspace_branch_info = {
        :branch => ws_branch_info[:branch],
        :module_name => ws_branch_info[:component_module_name],
        :repo_url => RepoManager.repo_url(ws_branch_info[:repo_name])
      }
      rest_ok_response workspace_branch_info
    end

    def rest__remove_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.remove_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response
    end

  end
end
