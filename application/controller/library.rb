module DTK
  class LibraryController < AuthController
    def rest__info_about()
      library = create_obj(:library_id)
      about = ret_non_null_request_params(:about).to_sym
      rest_ok_response library.info_about(about)
    end

#TODO: see which of below should be deprecated
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
