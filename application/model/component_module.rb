r8_require('service_or_component_module')
module DTK
  class ComponentModule < Model
    extend ServiceOrComponentModuleClassMixin
    
    def self.list(service_module_mh,opts={})
      library_idh = opts[:library_idh]
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => lib_filter
      }
      get_objs(service_module_mh,sp_hash)
    end

    def self.import(library_idh,remote_module_name)
      ret = nil
      module_name = remote_module_name
      if remote_already_imported?(library_idh,remote_module_name)
        raise Error.new("Cannot import remote repo (#{remote_module_name}) which has been imported already")
      end
      if conflicts_with_library_module?(library_idh,module_name)
        raise Error.new("Import conflicts with library module (#{module_name})")
      end

      #TODO: this might be done a priori
      Repo::Remote.authorize_dtk_instance(remote_module_name)

      #create empty repo on local repo manager; 
      config_agent_type = :puppet #TODO: hard wired
      #need to make sure that tests above indicate whether module exists already since using :delete_if_exists
      repo_obj = create_empty_repo_and_local_clone(library_idh,module_name,config_agent_type,:component_module,:remote_repo_name => remote_module_name,:delete_if_exists => true)
      repo_obj.synchronize_with_remote_repo()

      impl_obj = Implementation.create_library_impl?(library_idh,repo_obj,module_name,config_agent_type,"master")
      impl_obj.create_file_assets_from_dir_els(repo_obj)

      component_idhs = create_meta_info?(library_idh,impl_obj,repo_obj,config_agent_type)
      unless ::R8::Config[:use_modules]
        return ret
      end
      module_and_branch_idhs = create_module_and_branch_obj?(library_idh,repo_obj.id_handle(),module_name)
      update_components_with_branch_info(component_idhs,module_and_branch_idhs[:module_branch_idh])
      module_and_branch_idhs[:module_idh]
    end
    def self.delete(idh)
      delete_instance(idh)
    end
   private
    def self.create_meta_info?(library_idh,impl_obj,repo_obj,config_agent_type)
      local_dir = repo_obj.update_object!(:local_dir)[:local_dir]
      r8meta_path = "#{local_dir}/r8meta.#{config_agent_type}.yml"
      r8meta_hash = YAML.load_file(r8meta_path)
      add_library_components_from_r8meta(config_agent_type,library_idh,impl_obj.id_handle,r8meta_hash)
    end
    def self.update_components_with_branch_info(component_idhs,module_branch_idh)
      mb_id = module_branch_idh.get_id()
      update_rows = component_idhs.map{|cmp_idh|{:id=> cmp_idh.get_id(), :module_branch_id =>mb_id}}
      sample_cmp_idh = component_idhs.first 
      update_from_rows(sample_cmp_idh.createMH(),update_rows)
    end
  end
end
