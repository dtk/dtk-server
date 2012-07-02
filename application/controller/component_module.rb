module XYZ
  class Component_moduleController < Controller
    def rest__list_from_library()
      rest_ok_response ComponentModule.list_from_library(model_handle)
    end

    def rest__list_from_workspace()
      #TODO: update to call ComponentModule method
      rest_ok_response Implementation.list_from_workspace(model_handle(:implementation))
    end

    def rest__list_remote()
      rest_ok_response Repo::Remote.list(model_handle(:repo))
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
      #TODO: update to call ComponentModule method
      workspace_impl_id = ret_non_null_request_params(:implementation_id)
      workspace_impl = id_handle(workspace_impl_id,:implementation).create_object()
      workspace_impl.update_library_module_with_workspace()
      rest_ok_response
    end

    def rest__delete()
      component_module_id = ret_non_null_request_params(:component_module_id)
      ComponentModule.delete(id_handle(component_module_id))
      rest_ok_response
    end
  end
end
