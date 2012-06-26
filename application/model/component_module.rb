r8_require('service_or_component_module')
module XYZ
  class ComponentModule < Model
    extend ServiceOrComponentModuleClassMixin
    def self.import(library_idh,remote_module_name)
      module_name = remote_module_name
      if remote_already_imported?(library_idh,remote_module_name)
        raise Error.new("Cannot import remote repo (#{remote_module_name}) which has been imported already")
      end
      if conflict_with_local_repo?(library_idh,module_name)
        raise Error.new("Import conflicts with local repo (#{module_name})")
      end

      #TODO: this might be done a priori
      Repo::Remote.authorize_dtk_instance(remote_module_name)

      #create empty repo on local repo manager; 
      config_agent_type = :puppet #TODO: hard wired
      #need to make sure that tests above indicate whether module exists already since using :delete_if_exists
      repo_obj = create_empty_repo(library_idh,module_name,config_agent_type,:remote_repo_name => remote_module_name,:delete_if_exists => true)
      repo_obj.synchronize_with_remote_repo()

      impl_obj = Implementation.create_library_impl?(library_idh,repo_obj,module_name,config_agent_type,"master")
      impl_obj.create_file_assets_from_dir_els(repo_obj)

      create_meta_info?(library_idh,impl_obj,repo_obj,config_agent_type)

      #TODO: create component_module and cm_branch objects
      nil
    end
   private
    def self.create_meta_info?(library_idh,impl_obj,repo_obj,config_agent_type)
      local_dir = repo_obj.update_object!(:local_dir)[:local_dir]
      r8meta_path = "#{local_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash = YAML.load_file(r8meta_path)
      add_library_components_from_r8meta(config_agent_type,library_idh,impl_obj.id_handle,r8meta_hash)
    end
  end
end
