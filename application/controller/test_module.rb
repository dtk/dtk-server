module DTK
  class Test_moduleController < AuthController
    helper :module_helper
    helper :remotes_helper

    #### create and delete actions ###
    def rest__create
      module_name = ret_non_null_request_params(:module_name)
      namespace   = ret_request_param_module_namespace?()
      project     = get_default_project()
      version     = nil #TODO: stub

      opts_local_params = (namespace ? { namespace: namespace } : {})
      local_params = local_params(:test_module, module_name, opts_local_params)

      opts_create_mod = Opts.new(
        config_agent_type: ret_config_agent_type()
      )
      module_repo_info = TestModule.create_module(project, local_params, opts_create_mod)[:module_repo_info]
      rest_ok_response module_repo_info
    end

    def rest__update_from_initial_create
      test_module = create_obj(:test_module_id)
      repo_id, commit_sha = ret_non_null_request_params(:repo_id, :commit_sha)
      repo_idh = id_handle(repo_id, :repo)
      version = ret_version()
      scaffold = ret_request_params(:scaffold_if_no_dsl)
      opts = { scaffold_if_no_dsl: scaffold, do_not_raise: true, process_provider_specific_dependencies: true }
      rest_ok_response test_module.import_from_file(commit_sha, repo_idh, version, opts)
    end

    def rest__update_model_from_clone
      test_module = create_obj(:test_module_id)
      commit_sha = ret_non_null_request_params(:commit_sha)
      version = ret_version()
      diffs_summary = ret_diffs_summary()
      opts =  {}
      if ret_request_param_boolean(:internal_trigger)
        opts.merge!(do_not_raise: true)
      end
      if ret_request_param_boolean(:force_parse)
        opts.merge!(force_parse: true)
      end
      dsl_created_info = test_module.update_model_from_clone_changes?(commit_sha, diffs_summary, version, opts)
      rest_ok_response dsl_created_info
    end

    def rest__delete
      test_module = create_obj(:test_module_id)
      module_info = test_module.delete_object()
      rest_ok_response module_info
    end

    def rest__delete_version
      test_module = create_obj(:test_module_id)
      version = ret_version()
      module_info = test_module.delete_version(version)
      rest_ok_response module_info
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list
      diff             = ret_request_params(:diff)
      project          = get_default_project()
      datatype         = :module
      remote_repo_base = ret_remote_repo_base()

      opts = Opts.new(project_idh: project.id_handle())
      if detail = ret_request_params(:detail_to_include)
        opts.merge!(detail_to_include: detail.map(&:to_sym))
      end

      opts.merge!(remote_repo_base: remote_repo_base, diff: diff)
      datatype = :module_diff if diff

      rest_ok_response filter_by_namespace(TestModule.list(opts)), datatype: datatype
    end

    def rest__get_workspace_branch_info
      test_module = create_obj(:test_module_id)
      version = ret_version()
      rest_ok_response test_module.get_workspace_branch_info(version)
    end

    def rest__info
      module_id = ret_request_param_id_optional(:test_module_id, ::DTK::TestModule)
      project   = get_default_project()
      opts      = Opts.new(project_idh: project.id_handle())
      rest_ok_response TestModule.info(model_handle(), module_id, opts)
    end

    def rest__list_remote_diffs
      test_module = create_obj(:test_module_id)
      version = nil
      rest_ok_response test_module.list_remote_diffs(version)
    end

    #
    # Method will check new dependencies on repo manager and report missing dependencies.
    # Response will return list of modules for given component.
    #
    def rest__resolve_pull_from_remote
      rest_ok_response resolve_pull_from_remote(:test_module)
    end

    def rest__pull_from_remote
      rest_ok_response pull_from_remote_helper(TestModule)
    end

    def rest__remote_chmod
      response = chmod_from_remote_helper()
      rest_ok_response(response)
    end

    def rest__remote_chown
      chown_from_remote_helper()
      rest_ok_response
    end

    def rest__confirm_make_public
      rest_ok_response confirm_make_public_helper()
    end

    def rest__remote_collaboration
      collaboration_from_remote_helper()
      rest_ok_response
    end

    def rest__list_remote_collaboration
      response = list_collaboration_from_remote_helper()
      rest_ok_response response
    end

    def rest__versions
      test_module = create_obj(:test_module_id)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()
      opts = Opts.new(project_idh: project.id_handle())

      rest_ok_response test_module.local_and_remote_versions(client_rsa_pub_key, opts)
    end

    def rest__info_about
      test_module = create_obj(:test_module_id)
      about = ret_non_null_request_params(:about).to_sym
      component_template_id = ret_request_params(:component_template_id)
      unless AboutEnum.include?(about)
        fail ErrorUsage::BadParamValue.new(:about, AboutEnum)
      end
      rest_ok_response test_module.info_about(about, component_template_id)
    end

    AboutEnum = [:components, :attributes, :instances]

    #### end: list and info actions ###

    #### actions to interact with remote repos ###
    # TODO: rename; this is just called by install; import ops call create route
    def rest__import
      rest_ok_response install_from_dtkn_helper(:test_module)
    end

    # TODO: rename; this is just called by publish
    def rest__export
      test_module = create_obj(:test_module_id)
      rest_ok_response publish_to_dtkn_helper(test_module)
    end

    # this should be called when the module is linked, but the specfic version is not
    def rest__import_version
      test_module = create_obj(:test_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response test_module.import_version(remote_repo, version)
    end

    # TODO: ModuleBranch::Location: harmonize this signature with one for service module
    def rest__delete_remote
      remote_module_name = ret_non_null_request_params(:remote_module_name)
      remote_namespace = ret_request_params(:remote_module_namespace)
      force_delete = ret_request_param_boolean(:force_delete)

      remote_params = remote_params_dtkn(:test_module, remote_namespace, remote_module_name)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)

      project = get_default_project()
      TestModule.delete_remote(project, remote_params, client_rsa_pub_key, force_delete)
      rest_ok_response
    end

    def rest__list_remote
      test_modules = TestModule.list_remotes(model_handle, ret_request_params(:rsa_pub_key))
      rest_ok_response filter_by_namespace(test_modules), datatype: :module_remote
    end

    # get remote_module_info; throws an access rights usage error if user does not have access
    def rest__get_remote_module_info
      test_module = create_obj(:test_module_id)
      rest_ok_response get_remote_module_info_helper(test_module)
    end

    #### end: actions to interact with remote repo ###

    def rest__info_git_remote
      test_module = create_obj(:test_module_id)
      info_git_remote(test_module)
    end

    def rest__add_git_remote
      test_module = create_obj(:test_module_id)
      add_git_remote(test_module)
    end

    def rest__remove_git_remote
      test_module = create_obj(:test_module_id)
      remove_git_remote(test_module)
    end
  end
end
