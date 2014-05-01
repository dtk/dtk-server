module DTK; module ModuleMixins
  module Create
  end
  module Create::Class
    #TODO: ModuleBranch::Location: refactor like ModuleMixins::Remote::Class install
    #returns hash with keys :module_idh :module_branch_idh
    def create_module(project,module_name,opts={})
      #TODO: pass local_params in
      local_params = ModuleBranch::Location::LocalParams::Server.new(
        :module_type => module_type(),
        :module_name => module_name,
        :version => opts[:version]
      )

      local = local_params.create_local(project)

      project_idh = project.id_handle()

      is_parsed   = false
      if module_exists = module_exists?(project_idh,module_name)
        is_parsed = module_exists[:dsl_parsed] 
      end

      if is_parsed and not opts[:no_error_if_exists]
        raise ErrorUsage.new("Module (#{module_name}) cannot be created since it exists already")
      end
      create_opts = {
        :create_branch => local.branch_name(),
        :push_created_branch => true,
        :donot_create_master_branch => true,
        :delete_if_exists => true
      }
      repo_user_acls = RepoUser.authorized_users_acls(project_idh)
      local_repo_obj = Repo::WithBranch.create_empty_workspace_repo(project_idh,local,repo_user_acls,create_opts)

      module_and_branch_info = create_ws_module_and_branch_obj?(project,local_repo_obj.id_handle(),local.module_name,local.version)
      module_and_branch_info.merge(:module_repo_info => module_repo_info(local_repo_obj,module_and_branch_info,local.version))
    end

    def create_module_and_branch_obj?(project,repo_idh,local,ancestor_branch_idh=nil)
      project_idh = project.id_handle()
      ref = module_name = local.module_name
      opts = Hash.new
      opts.merge!(:ancestor_branch_idh => ancestor_branch_idh) if ancestor_branch_idh
      mb_create_hash = ModuleBranch.ret_create_hash(repo_idh,local,opts)
      version_field = mb_create_hash.values.first[:version]

      fields = {
        :display_name => module_name,
        :module_branch => mb_create_hash
      }

      create_hash = {
        model_name.to_s() => {
          ref => fields
        }
      }
      input_hash_content_into_model(project_idh,create_hash)
      module_branch = get_module_branch_from_local(local)
      module_idh =  project_idh.createIDH(:model_name => model_name(),:id => module_branch[:module_id])
      #TODO: ModuleBranch::Location: see if after refactor version field needed
      #TODO: ModuleBranch::Location: ones that come from local can be omitted
      {:version => version_field, :module_name => module_name, :module_idh => module_idh,:module_branch_idh => module_branch.id_handle()}
    end
    #TODO: ModuleBranch::Location: deprecate below for aboce
    def create_ws_module_and_branch_obj?(project,repo_idh,module_name,input_version,ancestor_branch_idh=nil)
      project_idh = project.id_handle()
      ref = module_name
      module_type = model_name.to_s
      opts = {:version => input_version}
      opts.merge!(:ancestor_branch_idh => ancestor_branch_idh) if ancestor_branch_idh
      mb_create_hash = ModuleBranch.ret_workspace_create_hash(project,module_type,repo_idh,opts)
      version = mb_create_hash.values.first[:version]

      fields = {
        :display_name => module_name,
        :module_branch => mb_create_hash
      }

      create_hash = {
        model_name.to_s => {
          ref => fields
        }
      }
      input_hash_content_into_model(project_idh,create_hash)

      module_branch = get_workspace_module_branch(project,module_name,version)
      module_idh =  project_idh.createIDH(:model_name => model_name(),:id => module_branch[:module_id])
      {:version => version, :module_name => module_name, :module_idh => module_idh,:module_branch_idh => module_branch.id_handle()}
    end
  end

  module Create::Instance
    def create_new_version(new_version,opts={},client_rsa_pub_key=nil)
      opts_get_aug = Opts.new
      if base_version = opts[:base_version]
        opts_get_aug.merge(:filter => {:version => base_version})
      end
      unless aug_ws_branch = get_augmented_workspace_branch(opts_get_aug)
        raise ErrorUsage.new("There is no module (#{pp_module_name()}) in the workspace")
      end

      #make sure there is a not an existing branch that matches the new one
      if get_module_branch_matching_version(new_version)
        raise ErrorUsage.new("Version exists already for module (#{pp_module_name(new_version)})")
      end
      repo_for_new_version = aug_ws_branch.create_new_branch_from_this_branch?(get_project(),aug_ws_branch[:repo],new_version)
      opts_type_spec = opts.merge(:ancestor_branch_idh => aug_ws_branch.id_handle())
      ret = create_new_version__type_specific(repo_for_new_version,new_version,opts_type_spec)
      opts[:ret_module_branch] = opts_type_spec[:ret_module_branch] if  opts_type_spec[:ret_module_branch]
      ret
    end
  end
end; end
