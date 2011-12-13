module XYZ
  class ImplementationController < Controller
###TODO: for testing
    #remove when finish testing
    #currently broken
    def test_extract(module_name)
      #a library should be passed as input; here we are just using teh users' private library
      library_idh = Library.get_users_private_library(model_handle(:library)).id_handle()
      config_agent_type = :puppet
      repo_obj,impl_obj = Implementation.create_library_repo_and_implementation(library_idh,module_name,config_agent_type, :delete_if_exists => true)
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

      impl_obj.add_library_files_from_directory(repo_obj)

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
      #simulating egtting resu
      #in between here refinement has would have through user interaction the user set the needed unknowns
      #refinement_hash is suppose to represent aplain hash
      
      object_form = meta_generator.reify(refinement_hash,module_name,config_agent_type)


      r8meta_hash = object_form.render_hash_form()
      #TODO: currently version not handled
      r8meta_hash.delete("version")
      r8meta_path = "#{module_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash.write_yaml(STDOUT)
      File.open(r8meta_path,"w"){|f|r8meta_hash.write_yaml(f)}

      Model.add_library_components_from_r8meta(config_agent_type,library_idh,impl_obj.id_handle,r8meta_hash)

      impl_obj.add_contained_files_and_push_to_repo()
      {:content => {}}
    end

    #TODO: may convert to get from git repo or process when git receive hooks
    def test_copy(module_name)
      #a library should be passed as input; here we are just using the public library
      library_idh = Library.get_public_library(model_handle(:library)).id_handle()
      config_agent_type = :puppet
      repo_obj,impl_obj = Implementation.create_library_repo_and_implementation(library_idh,module_name,config_agent_type, :delete_if_exists => true)
      module_dir = repo_obj[:local_dir]

      #copy files
      source_dir = "#{R8::EnvironmentConfig::SourceExternalRepoDir}/puppet/#{module_name}" 
      require 'fileutils'
      #TODO: more efficient to use copy pattern that does not include .git in first place
      FileUtils.cp_r "#{source_dir}/.", module_dir
      source_git = "#{source_dir}/.git"
      FileUtils.rm_rf source_git if File.directory?(source_git)

      #add file_assets
      impl_obj.add_library_files_from_directory(repo_obj)

      r8meta_path = "#{module_dir}/r8meta.#{config_agent_type}.yml"
      require 'yaml'
      r8meta_hash = YAML.load_file(r8meta_path)

      Model.add_library_components_from_r8meta(config_agent_type,library_idh,impl_obj.id_handle,r8meta_hash)

      impl_obj.add_contained_files_and_push_to_repo()
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
        proj_impl = Model.get_obj(idh.createMH,{:cols => [:id],:filer => [:eq, :ancestor_id,impl_hack[:id]]})
        proj_impl_id = proj_impl[:id]
      end

      impl = create_object_from_id(proj_impl_id)
      opts = {:include_file_assets => true}
      impl_tree = impl.get_module_tree(opts)

      {:data => impl_tree}
    end
  end
end
