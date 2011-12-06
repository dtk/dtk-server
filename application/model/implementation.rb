module XYZ
  class Implementation < Model
    #return [repo_obj,impl_obj]
    def self.create_library_repo_and_implementation(library_idh,module_name,config_agent_type,opts={})
      repo_obj = nil
      impl_obj = nil
      ret = [nil,nil]
      #create repo if it does not exist
      repo_mh = library_idh.createMH(:repo)
      repo_user_acls = %w{r8server}.map do |repo_username|
        {
          :repo_username => repo_username,
          :access_rights => "RW+"
        }
      end
      repo_obj = Repo.create(repo_mh,module_name,config_agent_type,repo_user_acls,opts)

      impl_hash = {
        :display_name => module_name,
        :type => ImplementationType[config_agent_type],
        :repo => repo_obj[:repo_name],
        :repo_id => repo_obj[:id],
        :module_name => module_name,
        :library_library_id => library_idh.get_id()
      }
      impl_ref = "#{config_agent_type}-#{module_name}"
      impl_mh = library_idh.create_childMH(:implementation)
      impl_idh = create_from_row?(impl_mh,impl_ref,{:ref => impl_ref},impl_hash)
      impl_obj = impl_idh.create_object().merge(impl_hash)
      [repo_obj, impl_obj]
    end

    def add_library_files_from_directory(repo_obj)
      module_dir = repo_obj[:local_dir]
      file_paths = Array.new
      Dir.chdir(module_dir) do
        pattern = "**/*"
        file_paths = Dir[pattern].select{|item|File.file?(item)}
      end

      file_type = ImplTypeToFileType[self[:type]]
      impl_id = id()
      file_asset_rows = file_paths.map do |file_path|
        file_name = file_path =~ Regexp.new("/([^/]+$)") ? $1 : file_path
        file_asset_ref = file_path.gsub(Regexp.new("/"),"_") #removing "/" since they confuse processing
        {
          :ref => file_asset_ref,
          :implementation_implementation_id => impl_id,
          :type => file_type,
          :display_name => file_name,
          :file_name => file_name,
          :path => file_path
        }
      end
      #TODO: need to make create? from rows
      Model.modify_children_from_rows(model_handle(:file_asset),id_handle,file_asset_rows)
    end

    def add_contained_files_and_push_to_repo()
      context = repo_manager_context()
      RepoManager.add_all_files(context)
      RepoManager.push_implementation(context)
    end

    def repo_manager_context()
      update_object!(:repo,:branch)
      {
        :implementation => {
          :repo => self[:repo],
          :branch => self[:branch]
        }
      }
    end
    private :repo_manager_context

    def get_tree(opts={})
      sp_hash = {:cols => [:id,:display_name,:component_template]}
      rows = get_objs(sp_hash)
      #all rows agree on everything but col
      ret = rows.first.reject{|k,v|k == :component}
      ret.merge!(:components => rows.map{|r|r[:component]})
      if opts[:include_file_assets]
        ret.merge!(:file_assets => self.class.get_indexed_asset_files([id_handle]))
      end
      ret
    end

    def get_asset_files()
      flat_file_assets = get_objs_col({:cols => [:file_assets]},:file_asset).reject{|k,v|k == :implementation_implementation_id}
      FileAsset.ret_hierrachical_file_struct(flat_file_assets)
    end

    #indexed by implementation_id
    def self.get_indexed_asset_files(id_handles)
      flat_file_assets = get_objects_in_set_from_sp_hash(id_handles,{:cols => [:id,:file_assets]})
      ret = Hash.new
      flat_file_assets.each do |r|
        pointer = ret[r[:id]] ||= Array.new
        file_asset = r[:file_asset].reject{|k,v|k == :implementation_implementation_id}
        FileAsset.set_hierrachical_file_struct!(pointer,file_asset)
      end
      ret
    end

    def clone_into_project_if_needed(project)
      proj_idh = project.id_handle()
      #check if there is a matching implementation aready in the project
      # mtach looks for match on rep and version
      base_sp_hash = {
        :model_name => :implementation,
        :filter => [:eq, :id, id()],
        :cols => [:repo, :version_num, :branch]
      }
      join_array = 
        [{
           :model_name => :implementation,
           :alias => :proj_impl,
           :convert => true,
           :join_type => :left_outer,
           :filter => [:eq, :project_project_id, proj_idh.get_id()],
           :join_cond => {:repo => :implementation__repo, :version_num => :implementation__version_num},
           :cols => [:id,:repo,:version_num]
         }]

      augmented_impl = Model.get_objects_from_join_array(model_handle(),base_sp_hash,join_array).first
      raise Error.new("No implementation for component") unless augmented_impl
      #return matching implementation idh if there is a match
      return augmented_impl[:proj_impl].id_handle() if augmented_impl[:proj_impl]

      #if reach here; no match and need to clone
      new_branch = augmented_impl.project_branch_name(project)
      RepoManager.clone_branch({:implementation => augmented_impl},new_branch)
      override_attrs={:branch => new_branch}
      new_impl_id = project.clone_into(self,override_attrs)
      id_handle(:id => new_impl_id, :model => :implementation)
    end

    #self is a project implementation; returns library implementation idh
    def clone_into_library_if_needed(library_idh)
      ret = nil
      #if implementation is updated, need to create a new implemntation in library; otherwise use
      update_object!(:updated,:repo,:branch)
      if self[:updated]
        new_version_num = get_new_version_num(library_idh)
        new_branch = library_branch_name(new_version_num,library_idh)
        #TODO: assuming that implementaion files do not hvae any content that is not written to repo
        RepoManager.clone_branch({:implementation => self},new_branch)
        override_attrs={:version_num => new_version_num,:branch => new_branch}
        new_impl_id = library_idh.create_object.clone_into(self,override_attrs)
        ret = id_handle(:model_name => :implemntation, :id => new_impl_id)
      else
        impl_obj = matching_library_template_exists?(self[:version_num],library_idh)
        raise Error.new("expected to find a matching library implemntation") unless impl_obj
        ret = impl_obj.id_handle
      end
      ret
    end

    #self is a project implementation
    def replace_library_impl_with_proj_impl()
      impl_objs_info = get_objs(:cols=>[:linked_library_implementation,:repo,:branch]).first
      raise Error.new("Cannot find associated library implementation") unless impl_objs_info
      library_impl = impl_objs_info[:library_implementation]
      project_impl = impl_objs_info
      RepoManager.merge_from_branch({:implementation => library_impl},project_impl[:branch])
      RepoManager.push_implementation(:implementation => library_impl)
    end

    def add_asset_file(path,content=nil)
      update_object!(:type,:repo,:branch)
      file_asset_type = FileAssetType[self[:type].to_sym]
      FileAsset.add(self,file_asset_type,path,content)
    end
    FileAssetType = { 
      :chef_cookbook => "chef_file"
    }

    def project_branch_name(project)
      project.update_object!(:ref)
      update_object!(:version_num,:repo)
      "project-#{project[:ref]}-v#{self[:version_num].to_s}"
    end

    def library_branch_name(new_version_num,library_idh)
      library = library_idh.create_object().update_object!(:ref)
      "library-#{library[:ref]}-v#{new_version_num.to_s}"
    end

    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:updated] ||= false
    end

    def set_to_indicate_updated()
      #TODO: short cut and avoid setting updated on project templates if impl set to updated already update({:updated => true},{:update_only_if_change => true})
      update(:updated => true)
      #set updated for the project templates that point to this implemntation
      cmp_mh = model_handle(:component)
      filter = [:and, [:eq, :implementation_id, id()], [:eq, :type, "template"]]
      Model.update_rows_meeting_filter(cmp_mh,{:updated => true},filter)
    end

    def create_pending_changes_and_clear_dynamic_attrs(file_asset)
      cmp_rows = get_objs({:cols => [:component_summary_info]})

      Component.clear_dynamic_attributes_and_their_dependents(cmp_rows.map{|r|r[:component].id_handle()})

      #TODO: make more efficient by using StateChange.create_pending_change_items
      cmp_rows.each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = cmp_idh.createIDH(:model_name => :datacenter, :id => r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(:new_item => cmp_idh, :parent => parent_idh, :type => "update_implementation")
      end
    end
    #TODO: deprecate below and replace by above
    def create_pending_change_item(file_asset)
      #TODO: make more efficient by using StateChange.create_pending_change_items
      get_objs({:cols => [:component_summary_info]}).each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = id_handle(:model_name => :datacenter, :id => r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(:new_item => cmp_idh, :parent => parent_idh, :type => "update_implementation")
      end
    end

   private
    ImplementationType = {
      :puppet => "puppet_module",
      :chef => "chef_cookbook"
    }
    ImplTypeToFileType = {
      "puppet_module" => "puppet_file",
      "chef_cookbook" => "chef_file"
    }

    def get_new_version_num(library_idh)
      #TODO: potential race condition in getting new version
      sp_hash = {
        :cols => [:version_num],
        :filter => [:and,
                    [:eq, :library_library_id, library_idh.get_id()],
                    [:eq, :repo, self[:repo]]]
      }
      impl_mh = model_handle(:implementatation)
      existing_ver_nums = get_objs(impl_mh,sp_hash).map{|r|r[:version_num]}
      1 + (existing_ver_nums.max||0)
    end

    def matching_library_template_exists?(version_num,library_idh)
      sp_hash = {
        :cols => [:id],
        :filter => [:and, 
                     [:eq, :library_library_id, library_idh.get_id()],
                     [:eq, :version_num, version_num],
                     [:eq, :repo, self[:repo]]]
      }
      Model.get_objs(model_handle,sp_hash).first
    end
  end
end

