module XYZ
  class Component_moduleController < Controller
    def rest__list_from_library()
      rest_ok_response ComponentModule.list_from_library(model_handle)
    end

    def rest__list_remote()
      rest_ok_response Repo::Remote.list(model_handle(:repo),:component_module)
    end

    def rest__import()
      remote_module_name = ret_non_null_request_params(:remote_module_name)
      library_id = ret_request_params(:library_id) 
      library_idh = (library_id && id_handle(library_id,:library)) || Library.get_public_library(model_handle(:library)).id_handle()
      unless library_idh
        raise Error.new("No library specified and no default can be determined")
      end
      ComponentModule.import(library_idh,remote_module_name)
      rest_ok_response
    end

    def rest__update_library()
      component_module_id = ret_non_null_request_params(:component_module_id)
      component_module = create_object_from_id(component_module_id)
      component_module.update_library_module_with_workspace()
      rest_ok_response
    end

    def rest__delete()
      component_module_id = ret_non_null_request_params(:component_module_id)
      ComponentModule.delete(id_handle(component_module_id))
      rest_ok_response
    end

    def rest__add_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.add_user_direct_access(model_handle,rsa_pub_key)
      rest_ok_response
    end

    def rest__remove_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.remove_user_direct_access(rsa_pub_key)
      rest_ok_response
    end
  end
end
