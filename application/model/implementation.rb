r8_nested_require('implementation','version')
r8_nested_require('implementation','branch_names')
r8_nested_require('implementation','create_workspace')
r8_nested_require('implementation','promote_module')
module XYZ
  class Implementation < Model
    include ImplVersionMixin
    include ImplBranchNamesMixin
    include ImplCreateWorkspaceMixin
    include ImplPromoteModuleMixin

    def self.list_from_library(impl_mh,opts={})
      library_idh = opts[:library_idh]
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => lib_filter
      }
      get_objs(impl_mh,sp_hash)
    end

    def self.list_from_workspace(impl_mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => [:neq, :project_project_id,nil]
      }
      get_objs(impl_mh,sp_hash)
    end

    #TODO: deprecate for methods on ComponentModule
    #return [repo_obj,impl_obj]
    def self.create_library_repo_and_implementation(library_idh,module_name,config_agent_type,opts={})
      repo_obj = nil
      impl_obj = nil
      ret = [nil,nil]

      #create repo if it does not exist
      repo_mh = library_idh.createMH(:repo)
      auth_repo_users = RepoUser.authorized_users(library_idh.createMH(:repo_user))
      repo_user_acls = auth_repo_users.map do |repo_username|
        {
          :repo_username => repo_username,
          :access_rights => "RW+"
        }
      end
      repo_obj = Repo.create_empty_repo(repo_mh,module_name,config_agent_type,repo_user_acls,opts)

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


    def self.delete_repos_and_implementations(model_handle,module_name)
      sp_hash = {
        :cols => [:id,:module_name,:repo_id],
        :filter => [:eq, :module_name, module_name]
      }
      impls = get_objs(model_handle,sp_hash)
      return if impls.empty?

      sp_hash = {
        :cols => [:id,:repo_name,:local_dir],
        :filter => [:oneof,:id,impls.map{|r|r[:repo_id]}.uniq]
      }
      repos = get_objs(model_handle.createMH(:repo),sp_hash)

      sp_hash = {
        :cols => [:id,:display_name],
        :filter => [:oneof,:implementation_id,impls.map{|r|r[:id]}.uniq]
      }
      cmps = get_objs(model_handle.createMH(:component),sp_hash)

      repos.each{|repo|RepoManager.delete_repo(repo)}

      Model.delete_instances(cmps.map{|cmp|cmp.id_handle()})
      Model.delete_instances(repos.map{|repo|repo.id_handle()})
      Model.delete_instances(impls.map{|impl|impl.id_handle()})
    end

    #TODO: this need s to be updated to rflect that can be on different branches
    def add_library_files_from_directory(repo_obj)
      update_object!(:type)
      repo_obj.update_object!(:local_dir)

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
          :path => file_path,
          :content => nil #TODO to clear model cache of content
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

    #TODO: unify with project#get_module_tree()
    def get_module_tree(opts={})
      sp_hash = {:cols => [:id,:display_name,:type,:project_project_id,:component_template]}
      rows_with_cmps = get_objs(sp_hash)

      i18n = get_i18n_mappings_for_models(:component)
      cmps = rows_with_cmps.map do |r|
        cmp = r[:component].materialize!(Component.common_columns())
        #TODO: see if cleaner way to put in i18n names
        cmp[:name] = i18n_string(i18n,:component, cmp[:name])
        cmp
      end
      #all rows common on all columns expect for :component
      ret_row = rows_with_cmps.first.reject{|k,v|k == :component}
      ret_row.merge!(:components => cmps)
      return [ret_row] unless opts[:include_file_assets]
      
      indexed_asset_files = Implementation.get_indexed_asset_files([id_handle])
      ret_row.merge!(:file_assets => indexed_asset_files.values.first)
      [ret_row]
    end

    #TODO deprecate
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
      flat_file_assets = get_objs_in_set(id_handles,{:cols => [:id,:file_assets]})
      ret = Hash.new
      flat_file_assets.each do |r|
        pointer = ret[r[:id]] ||= Array.new
        file_asset = r[:file_asset].reject{|k,v|k == :implementation_implementation_id}
        FileAsset.set_hierrachical_file_struct!(pointer,file_asset)
      end
      ret
    end

    def add_asset_file(path,content=nil)
      update_object!(:type,:repo,:branch)
      file_asset_type = FileAssetType[self[:type].to_sym]
      FileAsset.add(self,file_asset_type,path,content)
    end
    FileAssetType = { 
      :chef_cookbook => "chef_file"
    }

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
      #remove any node groups
      cmp_rows.reject!{|r|r[:node].is_node_group?}

      Component.clear_dynamic_attributes_and_their_dependents(cmp_rows.map{|r|r[:component].id_handle()})

      #TODO: make more efficient by using StateChange.create_pending_change_items
      cmp_rows.each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = cmp_idh.createIDH(:model_name => :datacenter, :id => r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(:new_item => cmp_idh, :parent => parent_idh, :type => "update_implementation")
      end
    end

    ImplementationType = {
      :puppet => "puppet_module",
      :chef => "chef_cookbook"
    }
    ImplTypeToFileType = {
      "puppet_module" => "puppet_file",
      "chef_cookbook" => "chef_file"
    }
  end
end

