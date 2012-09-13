r8_require('module_mixins')
module DTK
  class ComponentModule < Model
    extend ModuleClassMixin
    include ModuleMixin

    def create_new_version(new_version,existing_version=nil)
      update_object!(:display_name,:library_library_id)
      library_idh = id_handle(:model_name => :library, :id => self[:library_library_id])
      module_name = self[:display_name]

      matching_branches = get_module_branches_matching_version(existing_version)
      #check that there is a workspace branch
      unless ws_branch = find_branch(:workspace,matching_branches)
        raise ErrorUsage.new("There is no module (#{pp_module_name(existing_version)}) in the workspace")
      end

      #make sure there is a not a library branch that exists already
      if find_branch(:library,get_module_branches_matching_version(new_version))
        if new_version == existing_version
          raise ErrorUsage.new("Library version exists for module (#{pp_module_name(new_version)}); try using promote-to-library")
        else
          raise ErrorUsage.new("Library version exists for module (#{pp_module_name(new_version)})")
        end
      end

      new_lib_branch_name = ModuleBranch.library_branch_name(library_idh,new_version)
      repo = id_handle(:model_name => :repo, :id => ws_branch[:repo_id]).create_object()
      repo.add_library_branch?(ws_branch,new_lib_branch_name)
      self.class.create_objects_for_library_module(repo,library_idh,module_name,new_version)
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

    def get_associated_target_instances()
      get_objs_uniq(:target_instances)
    end

    def update_library_module_with_workspace(version=nil)
      aug_ws_branch_row = ModuleBranch.get_augmented_workspace_branch(self,version)
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


    #creates workspace branch (if needed) and related objects from library one
    def create_workspace_branch?(proj,version=nil)
      update_object!(:library_library_id,:display_name)

      #get library branch
      library_mb = get_library_module_branch(version)

      #create module branch for workspace if needed and pust it to repo server
      workspace_mb = library_mb.create_component_workspace_branch?(proj)
      RepoManager.push_implementation(workspace_mb)
      
      #create new project implementation if needed
      #  first get library implementation
      sp_hash = {
        :cols => [:id],
        :filter => [:and, [:eq, :library_library_id, self[:library_library_id]],
                    [:eq, :branch, branch],
                    [:eq, :module_name,self[:display_name]]]
      }
      library_impl = Model.get_obj(model_handlle(:implementation),sp_hash)
      new_impl_idh = library_impl.clone_into_project_if_needed(proj)

      #get repo info
      sp_hash = {
        :cols => [:id, :repo_name],
        :filter => [:eq, :id, workspace_mb[:repo_id]]
      }
      repo = Model.get_obj(model_handle(:repo),sp_hash)
      repo_name = repo[:repo_name]
      {
        :repo_name => repo_name,
        :branch => workspace_mb[:branch],
        :module_name => self[:display_name],
        :repo_url => RepoManager.repo_url(repo_name)
      }
    end

    def get_workspace_branch_info(version=nil)
      row = ModuleBranch.get_augmented_workspace_branch(self,version)
      repo_name = row[:workspace_repo][:repo_name]
      {
        :repo_name => repo_name,
        :branch => row[:branch],
        :module_name => row[:component_module][:display_name],
        :repo_url => RepoManager.repo_url(repo_name)
      }
    end


   private
    def self.import_postprocess(repo,library_idh,module_name,version)
      create_objects_for_library_module(repo,library_idh,module_name,version)
    end
    
    def self.create_objects_for_library_module(repo,library_idh,module_name,version)
      config_agent_type = :puppet #TODO: hard wired
      branch_name = ModuleBranch.library_branch_name(library_idh,version)
      impl_obj = Implementation.create_library_impl?(library_idh,repo,module_name,config_agent_type,branch_name,version)
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
