module XYZ
  class LibraryController < Controller
    def bind_to_repo_manager()
      
      #TODO: stub; this might be part of installation
    end

    def import_from_repo_manager()
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
