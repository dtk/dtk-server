module XYZ
  class ImplementationController < AuthController
#TODO: see what to keep
###TODO: for testing

    def delete_module(module_name)
      Implementation.delete_repos_and_implementations(model_handle,module_name)
      {:content => {}}
    end

###################
    def replace_library_implementation(proj_impl_id)
      create_object_from_id(proj_impl_id).replace_library_impl_with_proj_impl()
      return {:content => {}}
    end

    def get_tree(implementation_id)
      #TODO: should be passed proj_impl_id; below is hack to set if it is given libary ancesor
      impl_hack = create_object_from_id(implementation_id)
      if impl_hack.update_object!(:project_project_id)[:project_project_id]
        proj_impl_id = implementation_id
      else
        proj_impl = Model.get_obj(impl_hack.model_handle,{:cols => [:id],:filter => [:eq, :ancestor_id,impl_hack[:id]]})
        proj_impl_id = proj_impl[:id]
      end

      impl = create_object_from_id(proj_impl_id)
      opts = {:include_file_assets => true}
      impl_tree = impl.get_module_tree(opts)

      impl_tree.first[:id] = implementation_id.to_i #TODO: part of hack

      {:data => impl_tree}
    end
  end
end
