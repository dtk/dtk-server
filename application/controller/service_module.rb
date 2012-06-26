module XYZ
  class Service_moduleController < Controller
    def rest__create()
      module_name = ret_non_null_request_params(:module_name)
      library_id = ret_request_params(:library_id) 
      library_idh = (library_id && id_handle(library_id,:library)) || Library.get_public_library(model_handle(:library)).id_handle()
      unless library_idh
        raise Error.new("No library specified and no default can be determined")
      end
      service_module_idh = ServiceModule.create(library_idh,module_name)
      rest_ok_response(:service_module_id => service_module_idh.get_id())
    end
  end
end
