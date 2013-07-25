module XYZ
  class ImplementationController < AuthController
#TODO: see what to keep
###TODO: for testing

    def delete_module(module_name)
      Implementation.delete_repos_and_implementations(model_handle,module_name)
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
      impl_obj.create_file_assets_from_dir_els()

      r8meta_path = "#{module_dir}/r8meta.#{config_agent_type}.yml"
      require 'yaml'
      r8meta_hash = YAML.load_file(r8meta_path)

      ComponentDSL.add_components_from_r8meta(library_idh,config_agent_type,impl_obj.id_handle,r8meta_hash)

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
