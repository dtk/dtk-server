module XYZ
  class LibraryController < Controller
    def import_implementation(implementation_name)
      library_idh = Model.get_objs(model_handle,{:cols => [:id]}).first.id_handle() #TODO: stub
      ImportImplementationPackage.add(library_idh,implementation_name)
      {:content => {}}
    end 
  end
end
