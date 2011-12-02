module XYZ
  class ImplementationController < Controller
###TODO: for testing
    def test(repo_name)
      Repo.test_pp_config(model_handle(:repo_meta),repo_name)
      {:content => {}}
    end

    def test_extract(module_name)
      compressed_file = "#{R8::EnvironmentConfig::CompressedFileStore}/#{module_name}.tar.gz"
      config_agent_type = :puppet
      user_obj = CurrentSession.new.get_user_object()
      username = user_obj[:username]
      repo_name =  "#{username}-#{config_agent_type}-#{module_name}"

      opts = {:strip_prefix_count => 1} 
      base_dir = R8::EnvironmentConfig::ImportTestBaseDir

      #begin capture here so can rerun even after loading in dir already
      begin
        #extract tar.gz file into directory
        Extract.single_module_into_directory(compressed_file,repo_name,base_dir,opts)
      rescue Exception => e
        #raise e
      end
      module_dir = "#{base_dir}/#{repo_name}"

      user_group = user_obj.get_private_group()
      user_group_id = user_group && user_group[:id]
      top_container_idh = top_id_handle(:group_id => user_group_id)
      library_idh,impl_idh = Model.add_library_files_from_directory(top_container_idh,module_dir,module_name,config_agent_type)

      #create repo if it does not exist
      repo_meta_user_mh = top_container_idh.createMH(:repo_meta_user)
      repo_hash = {
        :config_agent_type => config_agent_type,
        :repo_name => module_name, #TODO: need to fix where the map from unqualified to qualified module names treated
        :repo_meta_user_acls =>
        %w{r8client r8server}.map do |repo_user|
          {:display_name => repo_user,
            #TODO: this should be done before hand and owner shoudl not be current user
            :repo_meta_user_id => RepoMetaUser.create?(repo_meta_user_mh,repo_user)[:id],
            :access_rights => "RW+"
          }
        end
      }
      
      Repo.create_repo?(top_container_idh.createMH(:repo_meta),repo_hash)

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
