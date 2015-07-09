r8_require('branch_names')

module DTK
  class Implementation < Model
    include BranchNamesMixin
    extend BranchNamesClassMixin

    def self.common_columns
      [:id,:group_id,:display_name,:type,:repo,:module_name,:module_namespace,:parse_state,:branch,:version,:updated,:repo_id,:assembly_id]
    end

    def modify_file_assets(diff_summary)
      paths_to_delete = diff_summary.paths_to_delete
      paths_to_add = diff_summary.paths_to_add

      # find relevant existing files
      sp_hash = {
        cols: [:id,:display_name,:path],
        filter: [:and,[:eq,:implementation_implementation_id,id()], [:oneof,:path,paths_to_delete+paths_to_add]]
      }
      file_assets = Model.get_objs(model_handle(:file_asset),sp_hash)
      # delete relevant files
      files_to_delete = file_assets.select{|r|paths_to_delete.include?(r[:path])}
      unless files_to_delete.empty?
        Model.delete_instances(files_to_delete.map(&:id_handle))
      end

      # add files not already added
      existing_paths = file_assets.map{|r|r[:path]}
      paths_to_add.reject!{|path|existing_paths.include?(path)}
      unless paths_to_add.empty?
        type = 'puppet_file' #TODO: hard coded
        create_rows =  paths_to_add.map{|path|FileAsset.ret_create_hash(self,type,path)}
        Model.create_from_rows(child_model_handle(:file_asset),create_rows)
      end
    end

    def self.create?(project,local_params,repo,config_agent_type)
      # was local = local_params.create_local(project) which is fine for import from puppet-forge
      # for import-git we use local object, so this is a temp workaround
      local = local_params.is_a?(ModuleBranch::Location::Server::Local) ? local_params : local_params.create_local(project)
      project = local.project
      version = local.version
      module_name = local.module_name
      module_namespace = local.module_namespace_name
      branch = local.branch_name

      match_assigns = {
        module_name: module_name,
        branch: branch,
        module_namespace: module_namespace
      }
      impl_hash = {
        display_name: version ? "#{module_name}(#{version})" : module_name,
        type: ImplementationType[config_agent_type],
        repo: repo.get_field?(:repo_name),
        repo_id: repo.id,
        project_project_id: project.id,
        version: version_field(version)
      }
      impl_ref = ref(module_namespace,module_name,branch)
      impl_mh = project.id_handle().create_childMH(:implementation)
      create_from_row?(impl_mh,impl_ref,match_assigns,impl_hash).create_object().merge(impl_hash)
    end

    def self.ref(namespace,module_name,branch)
      "#{namespace}-#{module_name}-#{branch}"
    end

    private_class_method :ref

    def add_file_and_push_to_repo(file_path,content,opts={})
      update_object!(:type,:repo,:branch)
      file_type = ImplTypeToFileType[self[:type]]
      FileAsset.add_and_push_to_repo(self,file_type,file_path,content,opts)
    end

    def create_file_assets_from_dir_els
      update_object!(:type,:repo,:branch)

      file_type = ImplTypeToFileType[self[:type]]
      file_asset_rows = all_file_paths().map do |file_path|
        content = nil #TODO: to clear model cache of content
        FileAsset.ret_create_hash(self,file_type,file_path,content)
      end
      return if file_asset_rows.empty?()

      # TODO: need to make create? from rows
      file_asset_mh = model_handle().create_childMH(:file_asset)
      Model.modify_children_from_rows(file_asset_mh,id_handle,file_asset_rows)
    end

    def all_file_paths
      RepoManager.ls_r('*',{file_only: true},self)
    end

    # TODO: Marked for removal [Haris]
    def add_contained_files_and_push_to_repo
      context = repo_manager_context()
      RepoManager.add_all_files(context)
      RepoManager.push_implementation(context)
    end

    def move_to_provider_subdir(source, destination)
      context = repo_manager_context()

      files   = (RepoManager.ls_r(1, {file_only: true} ,self)||[])
      files.reject!{|f| f=~DSLFilenameRegexp[1] || f=~DSLFilenameRegexp[2] || f=~DSLFilenameRegexp[3]}

      folders = (RepoManager.ls_r(1, {directory_only: true} ,self)||[]) - ExcludeFolders
      RepoManager.move_content(source, destination, files, folders, context)
    end
    DSLFilenameRegexp = {
      1 => /^r8meta\.[a-z]+\.([a-z]+$)/,
      2 => /^dtk\.model\.([a-z_]+$)/,
      3 => /^module_refs\.([a-z]+$)/
    }
    ExcludeFolders = ['puppet']

    def repo_manager_context
      update_object!(:repo,:branch)
      {
        implementation: {
          repo: self[:repo],
          branch: self[:branch]
        }
      }
    end
    private :repo_manager_context

    def get_module_branch
      get_obj(cols: [:repo_id,:branch,:module_branch])[:module_branch]
    end

    def get_asset_files
      flat_file_assets = get_objs_col({cols: [:file_assets]},:file_asset).reject{|k,_v|k == :implementation_implementation_id}
      FileAsset.ret_hierrachical_file_struct(flat_file_assets)
    end

    # indexed by implementation_id
    def self.get_indexed_asset_files(id_handles)
      flat_file_assets = get_objs_in_set(id_handles,cols: [:id,:file_assets])
      ret = {}
      flat_file_assets.each do |r|
        pointer = ret[r[:id]] ||= []
        file_asset = r[:file_asset].reject{|k,_v|k == :implementation_implementation_id}
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
      chef_cookbook: 'chef_file'
    }

    def add_model_specific_override_attrs!(override_attrs,_target_obj)
      override_attrs[:updated] ||= false
    end

    def set_to_indicate_updated
      # TODO: short cut and avoid setting updated on project templates if impl set to updated already update({:updated => true},{:update_only_if_change => true})
      update(updated: true)
      # set updated for the project templates that point to this implemntation
      cmp_mh = model_handle(:component)
      filter = [:and, [:eq, :implementation_id, id()], [:eq, :type, 'template']]
      Model.update_rows_meeting_filter(cmp_mh,{updated: true},filter)
    end

    def create_pending_changes_and_clear_dynamic_attrs(_file_asset)
      cmp_rows = get_objs(cols: [:component_summary_info])
      # remove any node groups
      cmp_rows.reject!{|r|r[:node].is_node_group?}

      Component.clear_dynamic_attributes_and_their_dependents(cmp_rows.map{|r|r[:component].id_handle()})

      # TODO: make more efficient by using StateChange.create_pending_change_items
      cmp_rows.each do |r|
        cmp_idh = r[:component].id_handle()
        parent_idh = cmp_idh.createIDH(model_name: :datacenter, id: r[:node][:datacenter_datacenter_id])
        StateChange.create_pending_change_item(new_item: cmp_idh, parent: parent_idh, type: 'update_implementation')
      end
    end

    ImplementationType = {
      puppet: 'puppet_module',
      chef: 'chef_cookbook'
    }
    ImplTypeToFileType = {
      'puppet_module' => 'puppet_file',
      'chef_cookbook' => 'chef_file'
    }

    # ####### TODO below related to UI and may deprecate

    # TODO: unify with project#get_module_tree()
    def get_module_tree(opts={})
      sp_hash = {cols: [:id,:display_name,:type,:project_project_id,:component_template]}
      rows_with_cmps = get_objs(sp_hash)

      i18n = get_i18n_mappings_for_models(:component)
      cmps = rows_with_cmps.map do |r|
        cmp = r[:component].materialize!(Component.common_columns())
        # TODO: see if cleaner way to put in i18n names
        cmp[:name] = i18n_string(i18n,:component, cmp[:name])
        cmp
      end
      # all rows common on all columns expect for :component
      ret_row = rows_with_cmps.first.reject{|k,_v|k == :component}
      ret_row.merge!(components: cmps)
      return [ret_row] unless opts[:include_file_assets]

      indexed_asset_files = Implementation.get_indexed_asset_files([id_handle])
      ret_row.merge!(file_assets: indexed_asset_files.values.first)
      [ret_row]
    end

    def get_tree(opts={})
      sp_hash = {cols: [:id,:display_name,:component_template]}
      rows = get_objs(sp_hash)
      # all rows agree on everything but col
      ret = rows.first.reject{|k,_v|k == :component}
      ret.merge!(components: rows.map{|r|r[:component]})
      if opts[:include_file_assets]
        ret.merge!(file_assets: self.class.get_indexed_asset_files([id_handle]))
      end
      ret
    end
  end
end
