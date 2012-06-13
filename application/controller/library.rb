module XYZ
  class LibraryController < Controller
    #TODO: stub; this might be part of installation
    def rest__bind_to_repo_manager()
      library_id = ret_request_params(:library_id) || Library.create_public_library?(model_handle()).get_id()
      create_object_from_id(library_id).bind_to_repo_manager()
      rest_ok_response
    end

    def rest__import_from_repo_manager()
      library_id = ret_request_params(:library_id) || Library.create_public_library?(model_handle()).get_id()
      repo_manager_hostname = ret_non_null_request_params(:repo_manager_hostname)
      create_object_from_id(library_id).import_from_repo_manager(repo_manager_hostname)
      rest_ok_response
    end

#TODO: see which of below shoudl be deprecated
    def import_implementation(implementation_name)
      library_idh = Model.get_objs(model_handle,{:cols => [:id]}).first.id_handle() #TODO: stub
      ImportImplementationPackage.add(library_idh,implementation_name)
      {:content => {}}
    end 

    def index
      tpl = R8Tpl::TemplateR8.new("ui/panel",user_context())
      tpl.set_js_tpl_name("ui_panel")
      tpl_info = tpl.render()
      include_js_tpl(tpl_info[:src])

      run_javascript("R8.LibraryView.init('#{model_name}');")
      return {:content => ''}      
    end
  end
end
