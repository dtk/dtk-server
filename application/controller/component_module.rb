require 'eventmachine'

module DTK
  class Component_moduleController < AuthController
    helper :module_helper
    helper :remotes_helper

    #### create and delete actions ###
    def rest__create
      # setup needed data
      module_name = ret_non_null_request_params(:module_name)
      namespace   = ret_request_param_module_namespace?()
      config_agent_type =  ret_config_agent_type()
      project = get_default_project()

      # local_params encapsulates local module branch params
      opts_local_params = (namespace ? { namespace: namespace } : {})
      local_params = local_params(:component_module,module_name,opts_local_params)

      opts_create_mod = Opts.new(
        config_agent_type: ret_config_agent_type()
      )
      module_repo_info = ComponentModule.create_module(project,local_params,opts_create_mod)[:module_repo_info]

      # only when creating via import-git command
      git_url = ret_request_params(:module_git_url)
      unless git_url.empty?
        add_git_url(project.model_handle(:repo_remote), module_repo_info[:repo_id], git_url)
      end

      rest_ok_response module_repo_info
    end

    def rest__update_from_initial_create
      component_module = create_obj(:component_module_id)
      repo_id,commit_sha = ret_non_null_request_params(:repo_id,:commit_sha)
      git_import = ret_request_params(:git_import)
      repo_idh = id_handle(repo_id,:repo)
      version = ret_version()
      scaffold = ret_request_params(:scaffold_if_no_dsl)
      opts = {scaffold_if_no_dsl: scaffold, do_not_raise: true, process_provider_specific_dependencies: true}
      opts.merge!(commit_dsl: true) if ret_request_params(:commit_dsl)

      response =
        if git_import
          component_module.import_from_git(commit_sha,repo_idh,version,opts)
        else
          component_module.import_from_file(commit_sha,repo_idh,version,opts)
        end

      rest_ok_response response
    end

    def rest__update_model_from_clone
      component_module = create_obj(:component_module_id)
      commit_sha    = ret_non_null_request_params(:commit_sha)
      version       = ret_version()
      diffs_summary = ret_diffs_summary()

      opts =  {}
      if ret_request_param_boolean(:internal_trigger)
        opts.merge!(do_not_raise: true)
      end
      if ret_request_param_boolean(:force_parse)
        opts.merge!(force_parse: true)
      end
      if ret_request_params(:set_parsed_false)
        opts.merge!(dsl_parsed_false: true)
      end
      if ret_request_params(:update_from_includes)
        opts.merge!(update_from_includes: true)
      end
      if ret_request_params(:service_instance_module)
        opts.merge!(service_instance_module: true)
      end
      if current_branch_sha = ret_request_params(:current_branch_sha)
        opts.merge!(current_branch_sha: current_branch_sha)
      end
      if force = ret_request_params(:force)
        opts.merge!(force: force)
      end

      # the possible keys in response are with the subkeys that are used
      #  :dsl_parse_error: ModuleDSL::ParsingError obj
      #  :dsl_updated_info:
      #    :msg
      #    :commit_sha
      #  :dsl_created_info
      #    :path
      #    :content - only if want this dsl file to be added on cleint side
      #  :external_dependencies
      #    :inconsistent
      #    :possibly_missing
      #    :ambiguous
      rest_ok_response component_module.update_model_from_clone_changes?(commit_sha,diffs_summary,version,opts)
    end

    def rest__delete
      component_module = create_obj(:component_module_id)
      module_info = component_module.delete_object()
      rest_ok_response module_info
    end

    def rest__delete_version
      component_module = create_obj(:component_module_id)
      version = ret_version()
      module_info = component_module.delete_version(version)
      rest_ok_response module_info
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list
      Log.info(MessageQueue.object_id)
      diff             = ret_request_params(:diff)
      project          = get_default_project()
      namespace        = ret_request_params(:module_namespace)
      datatype         = :module
      remote_repo_base = ret_remote_repo_base()

      opts = Opts.new(project_idh: project.id_handle())
      if detail = ret_request_params(:detail_to_include)
        opts.merge!(detail_to_include: detail.map(&:to_sym))
      end

      opts.merge!(remote_repo_base: remote_repo_base, diff: diff, namespace: namespace)
      datatype = :module_diff if diff

      # rest_ok_response filter_by_namespace(ComponentModule.list(opts)), :datatype => datatype
      rest_ok_response ComponentModule.list(opts), datatype: datatype
    end

    def rest__get_workspace_branch_info
      component_module = create_obj(:component_module_id)
      version = ret_version()
      rest_ok_response component_module.get_workspace_branch_info(version)
    end

    def rest__info
      module_id = ret_request_param_id_optional(:component_module_id, ::DTK::ComponentModule)
      project   = get_default_project()
      opts      = Opts.new(project_idh: project.id_handle())
      rest_ok_response ComponentModule.info(model_handle(), module_id, opts)
    end

    def rest__list_remote_diffs
      component_module = create_obj(:component_module_id)
      version = nil
      rest_ok_response component_module.list_remote_diffs(version)
    end

    #
    # Method will check new dependencies on repo manager and report missing dependencies.
    # Response will return list of modules for given component.
    #
    def rest__resolve_pull_from_remote
      rest_ok_response resolve_pull_from_remote(:component_module)
    end

    def rest__pull_from_remote
      rest_ok_response pull_from_remote_helper(ComponentModule)
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
      component_module = create_obj(:component_module_id)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()
      opts = Opts.new(project_idh: project.id_handle())

      rest_ok_response component_module.local_and_remote_versions(client_rsa_pub_key, opts)
    end

    def rest__info_about
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
    def rest__import
      rest_ok_response install_from_dtkn_helper(:component_module)
    end

    # TODO: rename; this is just called by publish
    def rest__export
      component_module = create_obj(:component_module_id)
      rest_ok_response publish_to_dtkn_helper(component_module)
    end

    def rest__install_puppet_forge_modules
      pf_full_name = ret_non_null_request_params(:puppetf_module_name)
      namespace,module_name = ret_namespace_and_module_name_for_puppet_forge(pf_full_name)
      puppet_version  = ret_request_params_force_nil(:puppet_version)
      project = get_default_project()

      # will raise exception if exists
      ComponentModule.if_module_exists!(project.id_handle(), module_name, namespace,
        "Cannot install '#{namespace}:#{module_name}' since it already exists!"
                                       )

      puppet_forge_local_copy = nil
      install_info = {}

      begin
        # will raise an exception in case of error
        # This creates a temporary directory after using puppet forge client to import
        MessageQueue.store(:info, "Started puppet forge install of module '#{pf_full_name}' ...")
        puppet_forge_local_copy = PuppetForge::Client.install(pf_full_name, puppet_version)
        opts = {config_agent_type: ret_config_agent_type()}
        opts = namespace ? {base_namespace: namespace} : {}
        MessageQueue.store(:info, 'Puppet forge module installed, parsing content ...')
        install_info = ComponentModule.import_from_puppet_forge(project, puppet_forge_local_copy, opts)
      ensure
        puppet_forge_local_copy.delete_base_install_dir?() if puppet_forge_local_copy
      end
      rest_ok_response install_info
    end

    # this should be called when the module is linked, but the specfic version is not
    def rest__import_version
      component_module = create_obj(:component_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response component_module.import_version(remote_repo,version)
    end

    # TODO: ModuleBranch::Location: harmonize this signature with one for service module
    def rest__delete_remote
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      remote_namespace = ret_request_params(:remote_module_namespace)
      force_delete = ret_request_param_boolean(:force_delete)

      opts = {}
      opts.merge!(namespace: remote_namespace) unless remote_namespace.empty?

      remote_namespace, remote_module_name = Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name), opts)
      remote_params = remote_params_dtkn(:component_module, remote_namespace, remote_module_name)

      project = get_default_project()
      ComponentModule.delete_remote(project, remote_params, client_rsa_pub_key, force_delete)

      rest_ok_response
    end

    def rest__list_remote
      module_list = ComponentModule.list_remotes(model_handle, ret_request_params(:rsa_pub_key))
      rest_ok_response filter_by_namespace(module_list), datatype: :module_remote
    end

    # get remote_module_info; throws an access rights usage error if user does not have access
    def rest__get_remote_module_info
      component_module = create_obj(:component_module_id)
      rest_ok_response get_remote_module_info_helper(component_module)
    end

    #### end: actions to interact with remote repo ###

    def rest__info_git_remote
      component_module = create_obj(:component_module_id)
      info_git_remote(component_module)
    end

    def rest__add_git_remote
      component_module = create_obj(:component_module_id)
      add_git_remote(component_module)
    end

    def rest__remove_git_remote
      component_module = create_obj(:component_module_id)
      remove_git_remote(component_module)
    end
  end
end
