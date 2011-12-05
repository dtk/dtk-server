module XYZ
  class ImplementationController < Controller
###TODO: for testing
    def test_extract(module_name)
      #a library should be passed as input; here we are just using teh users' private library
      library_idh = Library.get_users_private_library(model_handle(:library)).id_handle()
      config_agent_type = :puppet

      repo_obj,impl_idh = Implementation.create_library_repo_and_implementation?(library_idh,module_name,config_agent_type)
      repo_name = repo_obj[:repo_name]
      module_dir = repo_obj[:local_dir]
      base_dir = repo_obj[:base_dir]

      compressed_file = "#{R8::EnvironmentConfig::CompressedFileStore}/#{module_name}.tar.gz"

      opts = {:strip_prefix_count => 1} 

      #begin capture here so can rerun even after loading in dir already
      begin
        #extract tar.gz file into directory
        Extract.single_module_into_directory(compressed_file,repo_name,base_dir,opts)
      rescue Exception => e
        #raise e
      end

      #TODO: update so that takes repo_obj (and then can remove somne params; so can link from implementation to repo it uses 
      library_idh,impl_idh = Model.add_library_files_from_directory(top_container_idh,module_dir,module_name,config_agent_type)

      #parsing
      begin
        r8_parse = ConfigAgent.parse_given_module_directory(config_agent_type,module_dir)
       rescue ConfigAgent::ParseErrors => errors
        errors.set_file_asset_ids!(model_handle)
        pp [:puppet_error,errors.error_list.map{|e|e.to_s}]
        return {:content => {}}
       rescue R8ParseError => e
        pp [:r8_parse_error, e.to_s]
        return {:content => {}}
      end

      meta_generator = GenerateMeta.create("1.0")
      refinement_hash = meta_generator.generate_refinement_hash(r8_parse,module_name)
      #pp refinement_hash
        
        #in between here refinement has would have through user interaction the user set the needed unknowns
        #mock_user_updates_hash!(refinement_hash)
      r8meta_hash = refinement_hash.render_hash_form()
      #TODO: currently version not handled
      r8meta_hash.delete("version")
      r8meta_path = "#{module_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash.write_yaml(STDOUT)
      File.open(r8meta_path,"w"){|f|r8meta_hash.write_yaml(f)}
      Model.add_library_components_from_r8meta(config_agent_type,top_container_idh,library_idh,impl_idh,r8meta_hash)

      impl_idh.create_object().add_contained_files_and_push_to_repo()
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
