r8_require('module_mixins')
module DTK
  class ComponentModule < Model
    extend ModuleClassMixin
    include ModuleMixin

    def get_workspace_branch_info()
      row = get_augmented_workspace_branch()
      {
        :repo_name => row[:workspace_repo][:repo_name],
        :branch => row[:branch],
        :component_module_name => row[:component_module][:display_name]
      }
    end

    def get_associated_target_instances()
      get_objs_uniq(:target_instances)
    end

    def update_library_module_with_workspace()
      aug_ws_branch_row = get_augmented_workspace_branch()
      ModuleBranch.update_library_from_workspace?([aug_ws_branch_row],:ws_branch_augmented => true)
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

    def self.import(library_idh,remote_module_name,remote_namespace)
      ret = nil
      module_name = remote_module_name
      repo = common_import_steps(library_idh,remote_module_name,remote_namespace)

      config_agent_type = :puppet #TODO: hard wired
      impl_obj = Implementation.create_library_impl?(library_idh,repo,module_name,config_agent_type,"master")
      impl_obj.create_file_assets_from_dir_els(repo)

      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name)

      component_meta_file = ComponentMetaFile.create_meta_file_object(repo,impl_obj)
      component_idhs = component_meta_file.update_model()

      #TODO: remove below and put this log in component_meta_file.update_model()
      update_components_with_branch_info(component_idhs,module_and_branch_info[:module_branch_idh],module_and_branch_info[:version])
      module_and_branch_info[:module_idh]
    end

    def get_augmented_workspace_branch()
      sp_hash = {
        :cols => ModuleBranch.cols_for_matching_library_branches(model_name),
        :filter => [:and, [:eq, ModuleBranch.component_module_id_col(),id()],[:eq,:is_workspace,true]]
      }
      aug_ws_branch_rows = Model.get_objs(model_handle(:module_branch),sp_hash)
      if aug_ws_branch_rows.size != 1
        raise Error.new("error in finding unique workspace branch from component module")
      end
      aug_ws_branch_rows.first
    end

    def self.update_components_with_branch_info(component_idhs,module_branch_idh,version)
      mb_id = module_branch_idh.get_id()
      update_rows = component_idhs.map{|cmp_idh|{:id=> cmp_idh.get_id(), :module_branch_id =>mb_id,:version=>version}}
      sample_cmp_idh = component_idhs.first 
      update_from_rows(sample_cmp_idh.createMH(),update_rows)
    end
  end
end
