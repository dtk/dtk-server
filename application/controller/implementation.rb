module XYZ
  class ImplementationController < Controller
###TODO: for testing
    def test(repo_name)
      Repo.test_pp_config(model_handle(:repo_meta),repo_name)
      {:content => {}}
    end

    def test_extract(*compressed_file_x)
      compressed_file = "/" + compressed_file_x.join("/")
      Extract.into_directory(compressed_file,"/tmp/test")
    end
###################
    def replace_library_implementation(proj_impl_id)
      create_object_from_id(proj_impl_id).replace_library_impl_with_proj_impl()
      return {:content => {}}
    end

    def get_tree(implementation_id)
      impl = create_object_from_id(implementation_id)
      opts = {:include_file_assets => true}
      impl_tree = impl.get_tree(opts)

      {:data => impl_tree}
    end
  end
end
