module XYZ
  class ImplementationController < Controller
    def replace_library_implementation(proj_impl_id)
      create_object_from_id(proj_impl_id).replace_library_impl_with_proj_impl()
      return {:content => {}}
    end
  end
end
