r8_require('service_or_component_module')
module DTK
  class ComponentModule < Model
    extend ServiceOrComponentModuleClassMixin
    include ServiceOrComponentModuleMixin

    def update_library_module_with_workspace()
      #find augmented workspace branch
      sp_hash = {
        :cols => ModuleBranch.cols_for_matching_library_branches(model_name),
        :filter => [:and, [:eq, ModuleBranch.component_module_id_col(),id()],[:eq,:is_workspace,true]]
      }
      aug_ws_branch_rows = Model.get_objs(model_handle(:module_branch),sp_hash)
      if aug_ws_branch_rows.size != 1
        raise Error.new("error in finding unique workspace branch from component module")
      end
      ModuleBranch.update_library_from_workspace?(aug_ws_branch_rows,:augmented => true)
    end
    
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
        raise ErrorUsage.new("Cannot import remote repo (#{remote_module_name}) which has been imported already")
      end
      if conflicts_with_library_module?(library_idh,module_name)
        raise ErrorUsage.new("Import conflicts with library module (#{module_name})")
      end

      #TODO: this might be done a priori
      Repo::Remote.authorize_dtk_instance(remote_module_name)

      #create empty repo on local repo manager; 
      module_specific_type = config_agent_type = :puppet #TODO: hard wired
      #need to make sure that tests above indicate whether module exists already since using :delete_if_exists
      repo = create_empty_repo_and_local_clone(library_idh,module_name,module_specific_type,:remote_repo_name => remote_module_name,:delete_if_exists => true)
      repo.synchronize_with_remote_repo()

      impl_obj = Implementation.create_library_impl?(library_idh,repo,module_name,config_agent_type,"master")
      impl_obj.create_file_assets_from_dir_els(repo)


      component_meta_file = ComponentMetaFile.create_meta_file_object(repo,impl_obj)
      component_idhs = component_meta_file.update_model()

      unless ::R8::Config[:use_modules]
        return ret
      end
      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name)
      update_components_with_branch_info(component_idhs,module_and_branch_info[:module_branch_idh],module_and_branch_info[:version])
      module_and_branch_info[:module_idh]
    end

   private
    def self.update_components_with_branch_info(component_idhs,module_branch_idh,version)
      mb_id = module_branch_idh.get_id()
      update_rows = component_idhs.map{|cmp_idh|{:id=> cmp_idh.get_id(), :module_branch_id =>mb_id,:version=>version}}
      sample_cmp_idh = component_idhs.first 
      update_from_rows(sample_cmp_idh.createMH(),update_rows)
    end
  end
end
