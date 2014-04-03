module DTK
  class Service_moduleController < AuthController
    helper :module_helper
    helper :assembly_helper
    
    #TODO: for debugging; will be removed
    def rest__debug_get_project_trees()
      ServiceModule.get_project_trees(model_handle)
      rest_ok_response
    end

    def rest__debug_get_ports(service_module_id)
      service_module = create_object_from_id(service_module_id)
      service_module.get_ports()
      rest_ok_response
    end
    #end: for debugging; will be removed

    #### actions to interact with remote repos ###
    def rest__list_remote()
      rest_ok_response ServiceModule.list_remotes(model_handle, ret_request_params(:rsa_pub_key)), :datatype => :module_remote
    end

    def rest__list_assemblies()
      service_module_id = ret_request_param_id(:service_module_id)
      service_module = create_obj(:service_module_id)
      rest_ok_response service_module.get_assembly_templates()
    end

    def rest__list_instances()
      service_module_id = ret_request_param_id(:service_module_id)
      service_module = create_obj(:service_module_id)
      rest_ok_response service_module.get_assembly_instances()
    end

    def rest__list_component_modules()
      service_module_id = ret_request_param_id(:service_module_id)
      service_module = create_obj(:service_module_id)
      rest_ok_response service_module.get_referenced_component_modules(Opts.new(:detail_to_include=>[:versions]))
    end

    #TODO: rename; this is just called by install; import ops call create route
    def rest__import()
      rest_ok_response install_from_dtkn_helper(:service_module)
    end
    
    #this should be called when the module is linked, but the specfic version is not
    def rest__import_version()
      service_module = create_obj(:service_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response service_module.import_version(remote_repo,version)
    end

    def rest__export()
      service_module = create_obj(:service_module_id)
      remote_repo = ret_remote_repo()
      remote_comp_name = ret_params_hash_with_nil(:remote_component_name)[:remote_component_name]
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      
      service_module.export(remote_repo, nil, remote_comp_name, client_rsa_pub_key)
      rest_ok_response 
    end

    #get remote_module_info; throws an access rights usage eerror if user does not have access
    def rest__get_remote_module_info()
      service_module = create_obj(:service_module_id)
      rsa_pub_key,action = ret_non_null_request_params(:rsa_pub_key,:action)
      remote_namespace = ret_request_params(:remote_namespace)
      access_rights = ret_access_rights()
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response service_module.get_remote_module_info(action,remote_repo,rsa_pub_key,access_rights,version,remote_namespace)
    end


    def rest__pull_from_remote()
      rest_ok_response pull_from_remote_helper(ServiceModule)
    end

    #### end actions to interact with remote repos ###

    def rest__list()
      diff             = ret_request_params(:diff)
      project          = get_default_project()
      datatype         = :module
      remote_repo_base = ret_remote_repo_base()

      opts = Opts.new(:project_idh => project.id_handle())
      if detail = ret_request_params(:detail_to_include)
        opts.merge!(:detail_to_include => detail.map{|r|r.to_sym})
      end

      opts.merge!(:remote_repo_base => remote_repo_base, :diff => diff)
      datatype = :module_diff if diff

      rest_ok_response ServiceModule.list(opts), :datatype => datatype
    end

    def rest__versions()
      service_module = create_obj(:service_module_id)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()
      opts = Opts.new(:project_idh => project.id_handle())

      rest_ok_response service_module.local_and_remote_versions(client_rsa_pub_key, opts)
    end

    def rest__info()
      module_id = ret_request_param_id_optional(:service_module_id, ::DTK::ServiceModule)
      project   = get_default_project()
      opts      = Opts.new(:project_idh => project.id_handle())

      rest_ok_response ServiceModule.info(model_handle(), module_id, opts)
    end

    def rest__info_about()
      service_module = create_obj(:service_module_id)
      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum.include?(about)
        raise ErrorUsage::BadParamValue.new(:about,AboutEnum)
      end
      rest_ok_response service_module.info_about(about)
    end
    AboutEnum = ["assembly-templates".to_sym,:components]

    def rest__get_workspace_branch_info()
      service_module = create_obj(:service_module_id)
      version = ret_request_params(:version)
      rest_ok_response service_module.get_workspace_branch_info(version)
    end

    def rest__create()
      module_name = ret_non_null_request_params(:module_name)
      config_agent_type =  ret_config_agent_type()
      project = get_default_project()
      version = nil #TODO: stub
      opts = Opts.create?(
        :config_agent_type => config_agent_type,
        :version? => version
      )
      init_hash_response = ServiceModule.create_module(project,module_name,opts)
      rest_ok_response(:service_module_id => init_hash_response[:module_branch_idh].get_id(), :repo_info => init_hash_response[:module_repo_info])
    end

    def rest__create_new_version()
      service_module = create_obj(:service_module_id)
      version = ret_version()
      
      service_module.create_new_version(version)
      rest_ok_response
    end

    def rest__delete()
      service_module = create_obj(:service_module_id)
      module_info = service_module.delete_object()
      rest_ok_response module_info
    end

    def rest__delete_version()
      service_module = create_obj(:service_module_id)
      version = ret_version()
      module_info = service_module.delete_version(version)
      rest_ok_response module_info
    end

    def rest__delete_remote()
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_service_name))
      remote_params = create_remote_params_dtkn(:service_module,remote_namespace,remote_module_name,version)
      project = get_default_project()
      ServiceModule.delete_remote(project,remote_params,client_rsa_pub_key)
      rest_ok_response 
    end

    #
    # Method will check new dependencies on repo manager and report missing dependencies.
    # Response will return list of modules for given component.
    #
    def rest__resolve_pull_from_remote()
      service_module = create_obj(:service_module_id)
      opts = Opts.create?(:remote_namespace? => ret_request_params(:remote_namespace))
      module_name, namespace, version = service_module.get_basic_info(opts)
      remote_params = create_remote_params_dtkn(:service_module,namespace,module_name,version)
      rest_ok_response get_service_dependencies(remote_params)
    end

    def rest__delete_assembly_template()
      # using ret_assembly_params_id_and_subtype to get asembly_template_id
      assembly_id, subtype = ret_assembly_params_id_and_subtype()
      rest_ok_response Assembly::Template.delete_and_ret_module_repo_info(id_handle(assembly_id))
    end

    def rest__update_model_from_clone()
      service_module = create_obj(:service_module_id)
      commit_sha = ret_non_null_request_params(:commit_sha)
      version = ret_version()
      diffs_summary = ret_diffs_summary()
      opts = Hash.new
      if ret_request_param_boolean(:internal_trigger)
        opts.merge!(:do_not_raise => true )
      end
      if mod_type = ret_request_params(:modification_type)
        opts.merge!(:modification_type =>  mod_type.to_sym)
      end
      if ret_request_param_boolean(:force_parse)
        opts.merge!(:force_parse=> true)
      end
      rest_ok_response service_module.update_model_from_clone_changes?(commit_sha,diffs_summary,version,opts)
    end

    def rest__set_component_module_version()
      service_module = create_obj(:service_module_id)
      component_module = create_obj(:component_module_id,ComponentModule)
      version = ret_version()
      clone_update_info = service_module.set_component_module_version(component_module,version)
      rest_ok_response clone_update_info
    end

  end
end
