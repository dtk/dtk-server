r8_require('branch_names')
module XYZ
  class Implementation < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin

    def modify_file_assets(diff_summary)
      paths_to_delete = diff_summary.paths_to_delete
      paths_to_add = diff_summary.paths_to_add

      # find relevant existing files
      sp_hash = {
        :cols => [:id,:display_name,:path],
          :filter => [:and,[:eq,:implementation_implementation_id,id()], [:oneof,:path,paths_to_delete+paths_to_add]]
      }
      file_assets = Model.get_objs(model_handle(:file_asset),sp_hash)
      # delete relevant files
      files_to_delete = file_assets.select{|r|paths_to_delete.include?(r[:path])}
      unless files_to_delete.empty?
        Model.delete_instances(files_to_delete.map{|r|r.id_handle()})
      end

      # add files not already added
      existing_paths = file_assets.map{|r|r[:path]}
      paths_to_add.reject!{|path|existing_paths.include?(path)}
      unless paths_to_add.empty?
        type = "puppet_file" #TODO: hard coded
        create_rows =  paths_to_add.map{|path|FileAsset.ret_create_hash(self,type,path)}
        Model.create_from_rows(child_model_handle(:file_asset),create_rows)
      end
    end

    def self.list_from_workspace(impl_mh,opts={})
      sp_hash = {
        :cols => [:id, :display_name,:version],
        :filter => [:neq, :project_project_id,nil]
      }
      get_objs(impl_mh,sp_hash)
    end

    def self.create_workspace_impl?(project_idh,repo_obj,module_name, config_agent_type,branch,version=nil,module_namespace=nil)
      repo_obj.update_object!(:repo_name)
      impl_ref = ref(config_agent_type,module_name,branch)
      impl_hash = {
        :display_name => version ? "#{module_name}(#{version})" : module_name,
        :type => ImplementationType[config_agent_type],
        :repo => repo_obj[:repo_name],
        :repo_id => repo_obj[:id],
        :project_project_id => project_idh.get_id(),
        :version => version_field(version)
      }
      impl_mh = project_idh.create_childMH(:implementation)
      impl_idh = create_from_row?(impl_mh,impl_ref,{:module_name => module_name, :branch => branch, :module_namespace => module_namespace},impl_hash)
      impl_idh.create_object().merge(impl_hash)
    end

    class << self
      private
      def ref(config_agent_type,module_name,branch)
        "#{config_agent_type}-#{module_name}-#{branch}"
      end
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

    def add_file_and_push_to_repo(file_path,content,opts={})
      update_object!(:type,:repo,:branch)
      file_type = ImplTypeToFileType[self[:type]]
      FileAsset.add_and_push_to_repo(self,file_type,file_path,content,opts)
    end

    def create_file_assets_from_dir_els()
      update_object!(:type,:repo,:branch)

      file_type = ImplTypeToFileType[self[:type]]
      file_asset_rows = all_file_paths().map do |file_path|
        content = nil #TODO to clear model cache of content
        FileAsset.ret_create_hash(self,file_type,file_path,content)
      end
      return if file_asset_rows.empty?()

      # TODO: need to make create? from rows
      file_asset_mh = model_handle().create_childMH(:file_asset)
      Model.modify_children_from_rows(file_asset_mh,id_handle,file_asset_rows)
    end

    def all_file_paths()
      RepoManager.ls_r('*',{:file_only=>true},self)
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

    def get_module_branch()
      get_obj(:cols => [:repo_id,:branch,:module_branch])[:module_branch]
    end

    # TODO: unify with project#get_module_tree()
    def get_module_tree(opts={})
      sp_hash = {:cols => [:id,:display_name,:type,:project_project_id,:component_template]}
      rows_with_cmps = get_objs(sp_hash)

      i18n = get_i18n_mappings_for_models(:component)
      cmps = rows_with_cmps.map do |r|
        cmp = r[:component].materialize!(Component.common_columns())
        # TODO: see if cleaner way to put in i18n names
        cmp[:name] = i18n_string(i18n,:component, cmp[:name])
        cmp
      end
      # all rows common on all columns expect for :component
      ret_row = rows_with_cmps.first.reject{|k,v|k == :component}
      ret_row.merge!(:components => cmps)
      return [ret_row] unless opts[:include_file_assets]

      indexed_asset_files = Implementation.get_indexed_asset_files([id_handle])
      ret_row.merge!(:file_assets => indexed_asset_files.values.first)
      [ret_row]
    end

    # TODO deprecate
    def get_tree(opts={})
      sp_hash = {:cols => [:id,:display_name,:component_template]}
      rows = get_objs(sp_hash)
      # all rows agree on everything but col
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

    # indexed by implementation_id
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
      # TODO: short cut and avoid setting updated on project templates if impl set to updated already update({:updated => true},{:update_only_if_change => true})
      update(:updated => true)
      # set updated for the project templates that point to this implemntation
      cmp_mh = model_handle(:component)
      filter = [:and, [:eq, :implementation_id, id()], [:eq, :type, "template"]]
      Model.update_rows_meeting_filter(cmp_mh,{:updated => true},filter)
    end

    def create_pending_changes_and_clear_dynamic_attrs(file_asset)
      cmp_rows = get_objs({:cols => [:component_summary_info]})
      # remove any node groups
      cmp_rows.reject!{|r|r[:node].is_node_group?}

      Component.clear_dynamic_attributes_and_their_dependents(cmp_rows.map{|r|r[:component].id_handle()})

      # TODO: make more efficient by using StateChange.create_pending_change_items
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

