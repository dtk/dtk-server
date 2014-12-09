r8_require('../../utils/internal/puppet_forge/client')

module DTK
  class Component_moduleController < AuthController
    helper :module_helper

    def rest__test_generate_dsl()
      component_module = create_obj(:component_module_id)
      dsl_created_info = component_module.test_generate_dsl()
      STDOUT << dsl_created_info[:content] << "\n"
      rest_ok_response
    end

    #### create and delete actions ###
    def rest__create()
      # setup needed data
      module_name = ret_non_null_request_params(:module_name)
      namespace = ret_request_param_module_namespace?()
      config_agent_type =  ret_config_agent_type()
      project = get_default_project()

      # local_params encapsulates local module branch params                           
      opts_local_params = (namespace ? {:namespace=>namespace} : {})
      local_params = local_params(:component,module_name,opts_local_params)

      opts_create_mod = Opts.new(
        :local_params => local_params,                                 
        :config_agent_type => ret_config_agent_type()
      )
      module_repo_info = ComponentModule.create_module(project,module_name,opts_create_mod)[:module_repo_info]
      rest_ok_response module_repo_info
    end

    def rest__update_from_initial_create()
      component_module = create_obj(:component_module_id)
      repo_id,commit_sha = ret_non_null_request_params(:repo_id,:commit_sha)
      repo_idh = id_handle(repo_id,:repo)
      version = ret_version()
      scaffold = ret_request_params(:scaffold_if_no_dsl)
      opts = {:scaffold_if_no_dsl => scaffold, :do_not_raise => true, :process_external_refs => true}
      rest_ok_response component_module.update_from_initial_create(commit_sha,repo_idh,version,opts)
    end

    def rest__update_model_from_clone()
      component_module = create_obj(:component_module_id)
      commit_sha = ret_non_null_request_params(:commit_sha)
      version = ret_version()
      diffs_summary = ret_diffs_summary()
      opts =  Hash.new
      if ret_request_param_boolean(:internal_trigger)
        opts.merge!(:do_not_raise => true)
      end
      if ret_request_param_boolean(:force_parse)
        opts.merge!(:force_parse=> true)
      end

      dsl_created_info = component_module.update_model_from_clone_changes?(commit_sha,diffs_summary,version,opts)
      rest_ok_response dsl_created_info
    end

    def rest__delete()
      component_module = create_obj(:component_module_id)
      module_info = component_module.delete_object()
      rest_ok_response module_info
    end

    def rest__delete_version()
      component_module = create_obj(:component_module_id)
      version = ret_version()
      module_info = component_module.delete_version(version)
      rest_ok_response module_info
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list()
      diff             = ret_request_params(:diff)
      project          = get_default_project()
      namespace        = ret_request_params(:module_namespace)
      datatype         = :module
      remote_repo_base = ret_remote_repo_base()

      opts = Opts.new(:project_idh => project.id_handle())
      if detail = ret_request_params(:detail_to_include)
        opts.merge!(:detail_to_include => detail.map{|r|r.to_sym})
      end

      opts.merge!(:remote_repo_base => remote_repo_base, :diff => diff, :namespace => namespace)
      datatype = :module_diff if diff

      # rest_ok_response filter_by_namespace(ComponentModule.list(opts)), :datatype => datatype
      rest_ok_response ComponentModule.list(opts), :datatype => datatype
    end

    def rest__get_workspace_branch_info()
      component_module = create_obj(:component_module_id)
      version = ret_version()
      rest_ok_response component_module.get_workspace_branch_info(version)
    end

    def rest__info()
      module_id = ret_request_param_id_optional(:component_module_id, ::DTK::ComponentModule)
      project   = get_default_project()
      opts      = Opts.new(:project_idh => project.id_handle())
      rest_ok_response ComponentModule.info(model_handle(), module_id, opts)
    end

    #
    # Method will check new dependencies on repo manager and report missing dependencies.
    # Response will return list of modules for given component.
    #
    def rest__resolve_pull_from_remote()
      rest_ok_response resolve_pull_from_remote(:component_module)
    end

    def rest__pull_from_remote()
      rest_ok_response pull_from_remote_helper(ComponentModule)
    end

    def rest__remote_chmod()
      chmod_from_remote_helper()
      rest_ok_response
    end

    def rest__remote_chown()
      chown_from_remote_helper()
      rest_ok_response
    end

    def rest__remote_collaboration()
      collaboration_from_remote_helper()
      rest_ok_response
    end

    def rest__list_remote_collaboration()
      response = list_collaboration_from_remote_helper()
      rest_ok_response response
    end

    def rest__versions()
      component_module = create_obj(:component_module_id)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()
      opts = Opts.new(:project_idh => project.id_handle())

      rest_ok_response component_module.local_and_remote_versions(client_rsa_pub_key, opts)
    end

    def rest__info_about()
      component_module = create_obj(:component_module_id)
      about = ret_non_null_request_params(:about).to_sym
      component_template_id = ret_request_params(:component_template_id)
      unless AboutEnum.include?(about)
        raise ErrorUsage::BadParamValue.new(:about,AboutEnum)
      end
      rest_ok_response component_module.info_about(about, component_template_id)
    end

    AboutEnum = [:components, :attributes, :instances]

    #### end: list and info actions ###

    #### actions to interact with remote repos ###
    # TODO: rename; this is just called by install; import ops call create route
    def rest__import()
      rest_ok_response install_from_dtkn_helper(:component_module)
    end

    # TODO: rename; this is just called by publish
    def rest__export()
      component_module = create_obj(:component_module_id)
      rest_ok_response publish_to_dtkn_helper(component_module)
    end

    def rest__install_puppet_module()
      puppet_module_name = ret_non_null_request_params(:puppetf_module_name)
      module_name = ret_non_null_request_params(:module_name)
      namespace = ret_request_param_module_namespace?()
      # DTK-1754: Haris: assuming :module_version is puppet, not dtk, version 
      # so renamed it here; we migt rename also in rest payload
      puppet_version  = ret_request_params_force_nil(:module_version)
      project = get_default_project()

      # will raise exception if not valid
      PuppetForge::Client.is_module_name_valid?(puppet_module_name, module_name)

      # will raise an exception in case of error
      response = PuppetForge::Client.install(puppet_module_name, puppet_version)

      # local params encapsulates local module branch params                           
      opts_local_params =  namespace ? {:namespace=>namespace} : {}
      local_params = local_params(:component,module_name,opts_local_params)

      opts_create_mod = Opts.new(
        :local_params => local_params,                                 
        :config_agent_type => ret_config_agent_type()
      )
      # module_info has has info about the specfic applicable branch
      module_info = ComponentModule.create_module(project,module_name,opts_create_mod)[:module_repo_info]

      commit_sha  = PuppetForge::Client.push_to_server(project,local_params,response['install_dir'], module_info[:repo_url], response['parent_install_dir'])

      module_id   = module_info[:module_id]
      full_module_name   = module_info[:full_module_name]

      component_module = get_obj(module_id)

      # Calculate dependencies
      missing, found, dw = ComponentModule.cross_reference_modules(
            Opts.new(:project_idh => get_default_project().id_handle()),
            response['module_dependencies'][:dependencies]
            )

      version = local_params.version

      # DTK-1754: Rich: put in different call (update_from_initial_create_and_commit_dsl) 
      # than update_from_initial_create which is combination of update_from_initial_create
      # and update_model_from_clone_changes?
#      dsl_info_response = component_module.update_from_initial_create(
#          commit_sha,
#          id_handle(module_info[:repo_id], :repo),
#          version,
#          { :scaffold_if_no_dsl => true, :do_not_raise => true, :process_external_refs => true }
#        )
      response = component_module.update_from_initial_create_and_commit_dsl(
        commit_sha,
        id_handle(module_info[:repo_id], :repo),                                                                         
        module_info[:module_branch_idh],
        local_params,
        { :scaffold_if_no_dsl => true, :do_not_raise => true, :process_external_refs => true }
      )
raise ErrorUsage.new("got here")
      rest_ok_response dsl_info_response.merge(:module_id => module_id, :version => version, :full_module_name => full_module_name, :missing_modules => missing, :found_modules => found)
    end

    # this should be called when the module is linked, but the specfic version is not
    def rest__import_version()
      component_module = create_obj(:component_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response component_module.import_version(remote_repo,version)
    end

    # TODO: ModuleBranch::Location: harmonize this signature with one for service module
    def rest__delete_remote()
      remote_module_name = ret_non_null_request_params(:remote_module_name)
      remote_namespace = ret_request_params(:remote_module_namespace)
      remote_params = remote_params_dtkn(:component_module,remote_namespace,remote_module_name)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()
      ComponentModule.delete_remote(project,remote_params,client_rsa_pub_key)
      rest_ok_response
    end

    def rest__list_remote()
      module_list = ComponentModule.list_remotes(model_handle, ret_request_params(:rsa_pub_key))
      rest_ok_response filter_by_namespace(module_list), :datatype => :module_remote
    end

    # get remote_module_info; throws an access rights usage error if user does not have access
    def rest__get_remote_module_info()
      component_module = create_obj(:component_module_id)
      rest_ok_response get_remote_module_info_helper(component_module)
    end

    #### end: actions to interact with remote repo ###

    #### actions to manage workspace

    def rest__create_new_version()
      component_module = create_obj(:component_module_id)
      version = ret_version()

      component_module.create_new_version(version)
      rest_ok_response
    end

    def rest__create_new_dsl_version()
      component_module = create_obj(:component_module_id)
      dsl_version = ret_non_null_request_params(:dsl_version).to_i
      module_version = ret_version()
      format = :json
      component_module.create_new_dsl_version(dsl_version,format,module_version)
      rest_ok_response
    end

    #### end: actions to manage workspace and promote changes from workspace to library ###

    def rest__push_to_mirror()
      component_module = create_obj(:component_module_id)
      mirror_host = ret_non_null_request_params(:mirror_host)
      component_module.push_to_mirror(mirror_host)
    end

  end
end
