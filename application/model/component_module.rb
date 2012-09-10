r8_require('module_mixins')
module DTK
  class ComponentModule < Model
    extend ModuleClassMixin
    include ModuleMixin

    def promote_to_library(new_version=nil)
      #TODO: if new_version.nil? then do merge, check if meta data changed and if so update meta
      # if version is non null then check if verion exists, if does not leevrage code for import
=begin
     fragment to modify for creating new version
      repo = get repo associated with this

      branch = ModuleBranch.library_branch_name(library_idh,new_version)
      repo.synchronize_with_local_branch(branch)
      leverage component#create_component_module_workspace?(proj) and do reverse of it from proj to libray
=end
      raise Error.new("TODO: new implemented yet #{self.inspect}, version = #{new_version.inspect}")
    end

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

   private
    def self.import_postprocess(repo,library_idh,remote_module_name,remote_namespace,version)
      module_name = remote_module_name

      config_agent_type = :puppet #TODO: hard wired
      branch = ModuleBranch.library_branch_name(library_idh,version)
      impl_obj = Implementation.create_library_impl?(library_idh,repo,module_name,config_agent_type,branch,version)
      impl_obj.create_file_assets_from_dir_els(repo)

      module_and_branch_info = create_lib_module_and_branch_obj?(library_idh,repo.id_handle(),module_name,version)
      module_branch_idh = module_and_branch_info[:module_branch_idh]

      ComponentMetaFile.update_model(repo,impl_obj,module_branch_idh,version)
      module_branch_idh
    end

    def export_preprocess(branch)
      #noop
    end
  end
end
