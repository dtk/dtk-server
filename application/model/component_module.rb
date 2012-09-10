r8_require('module_mixins')
module DTK
  class ComponentModule < Model
    extend ModuleClassMixin
    include ModuleMixin

    def create_new_version(new_version,existing_version=nil)
      matching_branches = get_module_branches_matching_version(existing_version)
      #check that there is a workspace branch
      unless ws_branch = find_branch(:workspace,matching_branches)
        raise ErrorUsage.new("There is no module (#{pp_module_name(existing_version)}) in the workspace")
      end

      #make sure there is a not a library branch
      if find_branch(:library,get_module_branches_matching_version(new_version))
        if new_version == existing_version
          raise ErrorUsage.new("Library version exists for module (#{pp_module_name(new_version)}); try using promote-to-library")
        else
          raise ErrorUsage.new("Library version exists for module (#{pp_module_name(new_version)})")
        end
      end

#NEW: leverage work did on import; may update when new version by using component_meta_file
      #TODO: if new_version.nil? then do merge, check if meta data changed and if so update meta
      # if version is non null then check if verion exists, if does not leevrage code for import
=begin
     fragment to modify for creating new version
      repo = get repo associated with this

      branch = ModuleBranch.library_branch_name(library_idh,new_version)
      repo.synchronize_with_local_branch(branch)
      leverage component#create_component_module_workspace?(proj) and do reverse of it from proj to libray
=end
    end

    #promotes workspace changes to library
    def promote_to_library(version=nil)
      matching_branches = get_module_branches_matching_version(version)
      #check that there is a workspace branch
      unless ws_branch = find_branch(:workspace,matching_branches)
        raise ErrorUsage.new("There is no module (#{pp_module_name(version)}) in the workspace")
      end

      #check that there is a library branch
      unless lib_branch =  find_branch(:library,matching_branches)
        raise Error.new("No library version exists for module (#{pp_module_name(version)}); try using create-new-version")
      end

      unless lib_branch[:repo_id] == ws_branch[:repo_id]
        raise Error.new("Not supporting case where promoting workspace to library branch when branches are on two different repos")
      end

      repo = id_handle(:model_name => :repo, :id => lib_branch[:repo_id]).create_object()
      result = repo.synchronize_library_with_workspace_branch(lib_branch,ws_branch)
      case result
      when :changed
        nil #no op
      when :no_change 
        raise ErrorUsage.new("For module (#{pp_module_name(version)}), workspace and library are identical")
      when :merge_needed
        raise ErrorUsage.new("In order to promote changes for module (#{pp_module_name(version)}), merge into workspace is needed")
      else
        raise Error.new("Unexpected result (#{result}) from synchronize_library_with_workspace_branch")
      end
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
    
    def self.list(mh,opts={})
      library_idh = opts[:library_idh]
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => lib_filter
      }
      ndx_module_info = get_objs(mh,sp_hash).inject(Hash.new()){|h,r|h.merge(r[:id] => r)}

      #get version info
      sp_hash = {
        :cols => [:component_id,:version],
        :filter => [:and,[:oneof, :component_id, ndx_module_info.keys], [:neq,:is_workspace,true]]
      }
      branch_info = get_objs(mh.createMH(:module_branch),sp_hash)
      #join in version info
      branch_info.each do |br|
        mod = ndx_module_info[br[:component_id]]
        version = ((br[:version].nil? or br[:version] == "master") ? "CURRENT" : br[:version])
        mdl = ndx_module_info[br[:component_id]]
        (mdl[:version_array] ||= Array.new) <<  version
      end
      #put version info in prin form
      ndx_module_info.values.map do |mdl|
        raw_va = mdl.delete(:version_array)
        unless raw_va.nil? or raw_va == ["CURRENT"]
          version_array = (raw_va.include?("CURRENT") ? ["CURRENT"] : []) + raw_va.reject{|v|v == "CURRENT"}.sort
          mdl.merge!(:version => version_array.join(", ")) #TODO: change to ':versions' after sync with client
        end
        mdl
      end
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

    #type is :library or :workspace
    def find_branch(type,branches)
      matches =
        case type
          when :library then branches.reject{|r|r[:is_workspace]} 
          when :workspace then branches.select{|r|r[:is_workspace]} 
          else raise Error.new("Unexpected type (#{type})")
        end
      if matches.size > 1
        Error.new("Unexpected that there is more than one matching #{type} branches")
      end
      matches.first
    end

    def export_preprocess(branch)
      #noop
    end
  end
end
