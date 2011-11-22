module XYZ
  class ImplementationController < Controller
###TODO: for testing
    def test(repo_name)
      Repo.test_pp_config(model_handle(:repo_meta),repo_name)
      {:content => {}}
    end

    def test_extract(module_name)
      compressed_file = "/tmp/#{module_name}.tar.gz"
      username = CurrentSession.new.get_user_object()[:username]
      repo_name =  "#{username}-puppet-#{module_name}"
      opts = {:strip_prefix_count => 1} 
      base_dir = "/tmp/test"

      #begin capture here so can rerun even after loading in dir already
      begin
        #extract tar.gz file into directory
        Extract.single_module_into_directory(compressed_file,repo_name,base_dir,opts)
      rescue
      end
      module_init_file = "#{base_dir}/#{repo_name}/manifests/init.pp"
      begin
        r8_parse = ConfigAgent.parse_given_filename(:puppet,module_init_file)
       rescue ::Puppet::Error => e
        pp [:puppet_error,e.to_s]
        return {:content => {}}
       rescue R8ParseError => e
        pp [:r8_parse_error, e.to_s]
        return {:content => {}}
      end
      pp r8_parse
=begin
      #pp r8_parse
      begin
        meta_generator = XYZ::GenerateMeta.create("1.0")
        #TODO: should be able to figure this out "puppet" from r8_parse
        refinement_hash = meta_generator.generate_refinement_hash(r8_parse,module_name)
        #pp refinement_hash
        
        #in between here refinement has would have through user interaction the user set the needed unknowns
        #mock_user_updates_hash!(refinement_hash)
        render_hash = refinement_hash.render_hash_form()
        render_hash.write_yaml(STDOUT)
=end
  {:content => {}}
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
