module DTK
  class Service_moduleController < AuthController
    helper :module_helper
    helper :assembly_helper
    helper :remotes_helper

    # TODO: for debugging; will be removed
    def rest__debug_get_project_trees
      ServiceModule.get_project_trees(model_handle)
      rest_ok_response
    end

    def rest__debug_get_ports(service_module_id)
      service_module = create_object_from_id(service_module_id)
      service_module.get_ports()
      rest_ok_response
    end
    # end: for debugging; will be removed

    #### actions to interact with remote repos ###
    def rest__list_remote
      rsa_pub_key = ret_request_params(:rsa_pub_key)
      datatype_opts = { datatype: :module_remote }
      module_list = ServiceModule.list_remotes(model_handle, rsa_pub_key)
      rest_ok_response filter_by_namespace(module_list), datatype_opts
    end

    def rest__list_assemblies
      service_module = create_obj(:service_module_id)
      rest_ok_response service_module.get_assembly_templates()
    end

    def rest__list_instances
      service_module = create_obj(:service_module_id)
      rest_ok_response service_module.get_assembly_instances()
    end

    def rest__list_component_modules
      service_module = create_obj(:service_module_id)
      opts = Opts.new(detail_to_include: [:versions])
      rest_ok_response service_module.list_component_modules(opts)
    end

    # TODO: rename; this is just called by install; import ops call create route
    def rest__import
      rest_ok_response install_from_dtkn_helper(:service_module)
    end

    # TODO: rename; this is just called by publish
    def rest__export
      service_module = create_obj(:service_module_id)
      rest_ok_response publish_to_dtkn_helper(service_module)
    end

    # this should be called when the module is linked, but the specfic version is not
    def rest__import_version
      service_module = create_obj(:service_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response service_module.import_version(remote_repo, version)
    end

    # get remote_module_info; throws an access rights usage error if user does not have access
    def rest__get_remote_module_info
      service_module = create_obj(:service_module_id)
      rest_ok_response get_remote_module_info_helper(service_module)
    end

    def rest__pull_from_remote
      rest_ok_response pull_from_remote_helper(ServiceModule)
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

    #### end actions to interact with remote repos ###

    def rest__list
      diff             = ret_request_params(:diff)
      project          = get_default_project()
      datatype         = :module
      namespace        = ret_request_params(:module_namespace)
      remote_repo_base = ret_remote_repo_base()

      opts = Opts.new(project_idh: project.id_handle())
      if detail = ret_request_params(:detail_to_include)
        opts.merge!(detail_to_include: detail.map(&:to_sym))
      end

      opts.merge!(remote_repo_base: remote_repo_base, diff: diff, namespace: namespace)
      datatype = :module_diff if diff

      # rest_ok_response filter_by_namespace(ServiceModule.list(opts)), :datatype => datatype
      rest_ok_response ServiceModule.list(opts), datatype: datatype
    end

    def rest__versions
      service_module = create_obj(:service_module_id)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()
      opts = Opts.new(project_idh: project.id_handle())

      rest_ok_response service_module.local_and_remote_versions(client_rsa_pub_key, opts)
    end

    def rest__list_remote_diffs
      service_module = create_obj(:service_module_id)
      version = nil
      rest_ok_response service_module.list_remote_diffs(version)
    end

    def rest__info
      module_id = ret_request_param_id_optional(:service_module_id, ::DTK::ServiceModule)
      project   = get_default_project()
      opts      = Opts.new(project_idh: project.id_handle())

      rest_ok_response ServiceModule.info(model_handle(), module_id, opts)
    end

    def rest__info_about
      service_module = create_obj(:service_module_id)
      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum.include?(about)
        fail ErrorUsage::BadParamValue.new(:about, AboutEnum)
      end
      rest_ok_response service_module.info_about(about)
    end
    AboutEnum = ['assembly-templates'.to_sym, :components]

    def rest__get_workspace_branch_info
      service_module = create_obj(:service_module_id)
      version = ret_request_params(:version)
      rest_ok_response service_module.get_workspace_branch_info(version)
    end

    def rest__create
      module_name       = ret_non_null_request_params(:module_name)
      namespace         = ret_request_param_module_namespace?()
      config_agent_type =  ret_config_agent_type()
      project           = get_default_project()
      version           = nil #TODO: stub

      opts_local_params = (namespace ? { namespace: namespace } : {})
      local_params = local_params(:service_module, module_name, opts_local_params)

      opts_create_mod = Opts.new(
        config_agent_type: ret_config_agent_type()
      )
      init_hash_response = ServiceModule.create_module(project, local_params, opts_create_mod)

      rest_ok_response(service_module_id: init_hash_response[:module_branch_idh].get_id(), repo_info: init_hash_response[:module_repo_info])
    end

    def rest__delete
      service_module = create_obj(:service_module_id)
      module_info = service_module.delete_object()
      rest_ok_response module_info
    end

    def rest__delete_version
      service_module = create_obj(:service_module_id)
      version = ret_version()
      module_info = service_module.delete_version(version)
      rest_ok_response module_info
    end

    def rest__delete_remote
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      remote_namespace = ret_request_params(:remote_module_namespace)
      force_delete = ret_request_param_boolean(:force_delete)

      opts = {}
      opts.merge!(namespace: remote_namespace) unless remote_namespace.empty?

      remote_namespace, remote_module_name, version = Repo::Remote.split_qualified_name(ret_non_null_request_params(:remote_module_name), opts)
      remote_params = remote_params_dtkn(:service_module, remote_namespace, remote_module_name, version)

      project = get_default_project()
      ServiceModule.delete_remote(project, remote_params, client_rsa_pub_key, force_delete)

      rest_ok_response
    end

    #
    # Method will check new dependencies on repo manager and report missing dependencies.
    # Response will return list of modules for given component.
    #
    def rest__resolve_pull_from_remote
      rest_ok_response resolve_pull_from_remote(:service_module)
    end

    def rest__delete_assembly_template
      assembly_template_idh = ret_assembly_template_idh()
      rest_ok_response Assembly::Template.delete_and_ret_module_repo_info(assembly_template_idh)
    end

    def rest__update_model_from_clone
      service_module = create_obj(:service_module_id)
      commit_sha = ret_non_null_request_params(:commit_sha)
      version = ret_version()
      diffs_summary = ret_diffs_summary()
      opts = ret_params_hash(:task_action)
      opts.merge!(auto_update_module_refs: true) # TODO: might make this contingent
      if ret_request_param_boolean(:internal_trigger)
        opts.merge!(do_not_raise: true)
      end
      if mod_type = ret_request_params(:modification_type)
        opts.merge!(modification_type: mod_type.to_sym)
      end
      if ret_request_param_boolean(:force_parse)
        opts.merge!(force_parse: true)
      end
      rest_ok_response service_module.update_model_from_clone_changes?(commit_sha, diffs_summary, version, opts)
    end

    def rest__set_component_module_version
      service_module = create_obj(:service_module_id)
      component_module = create_obj(:component_module_id, ComponentModule)
      version = ret_version()
      clone_update_info = service_module.set_component_module_version(component_module, version)
      rest_ok_response clone_update_info
    end

    def rest__info_git_remote
      service_module = create_obj(:service_module_id)
      info_git_remote(service_module)
    end

    def rest__add_git_remote
      service_module = create_obj(:service_module_id)
      add_git_remote(service_module)
    end

    def rest__remove_git_remote
      service_module = create_obj(:service_module_id)
      remove_git_remote(service_module)
    end
  end
end
