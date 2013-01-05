module DTK
  class Component_moduleController < AuthController
    helper :module_helper

def rest__test_generate_dsl()
  component_module = create_obj(:component_module_id)
  dsl_created = component_module.test_generate_dsl()
  STDOUT << dsl_created[:content] << "\n"
  rest_ok_response
end

    #### create and delete actions ###
    def create_empty_repo()
      module_name = ret_non_null_request_params(:component_module_name)
      library_idh = ret_library_idh_or_default()
      project = get_default_project()
      module_repo_info = ComponentModule.create_empty_repo(library_idh,project,module_name)
      rest_ok_response module_repo_info
    end

    #TODO: rename to rest__update_repo_and_add_dsl_data(), input field :scaffold_if_no_dsl -> :scaffold_if_no_dsl and output field :dsl_created -> :dsl_craeted
    def rest__update_repo_and_add_dsl()
      repo_id,library_id,module_name = ret_non_null_request_params(:repo_id,:library_id,:module_name)
      version,scaffold = ret_request_params(:version,:scaffold_if_no_dsl)
      opts = {:scaffold_if_no_dsl => scaffold}
      repo_idh = id_handle(repo_id,:repo)
      library_idh = id_handle(library_id,:library)
      project = get_default_project()
      dsl_created = ComponentModule.update_repo_and_add_dsl(repo_idh,library_idh,project,module_name,version,opts)[:dsl_created]
      rest_ok_response :dsl_created => dsl_created
    end

    def rest__update_model_from_clone()
      component_module = create_obj(:component_module_id)
      version = ret_request_params(:version)
      json_diffs = ret_request_params(:json_diffs)
      diffs_summary = Repo::Diffs::Summary.new(json_diffs && JSON.parse(json_diffs))
      component_module.update_model_from_clone_changes?(diffs_summary,version)
      rest_ok_response
    end

    def rest__delete()
      component_module_id = ret_request_param_id(:component_module_id)
      module_info = ComponentModule.delete(id_handle(component_module_id))
      rest_ok_response module_info
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list()
      project = get_default_project()
      rest_ok_response ComponentModule.list(model_handle, :project_idh => project.id_handle())
    end

    def rest__get_workspace_branch_info()
      component_module = create_obj(:component_module_id)
      version = ret_request_params(:version)
      rest_ok_response component_module.get_workspace_branch_info(version)
    end

    def rest__get_all_workspace_library_diffs()
      rest_ok_response ComponentModule.get_all_workspace_library_diffs(model_handle)
    end

    def rest__info_about()
      component_module = create_obj(:component_module_id)
      about = ret_non_null_request_params(:about).to_sym
      unless AboutEnum.include?(about)
        raise ErrorUsage::BadParamValue.new(:about,AboutEnum)
      end
      rest_ok_response component_module.info_about(about)
    end
    AboutEnum = [:components]

    #### end: list and info actions ###
    
    #### actions to interact with remote repos ###
    def rest__import()
      remote_repo = ret_remote_repo()
      project = get_default_project()
      ret_non_null_request_params(:remote_module_names).each do |name|
        remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(name)
        remote_params = {
          :repo => remote_repo,
          :namespace => remote_namespace,
          :module_name => remote_module_name,
          :version => version
        }
        local_params = {
          :module_name => remote_module_name #TODO: hard coded making local module name same as remote module_name
        }
        ComponentModule.import(project,remote_params,local_params)
      end
      rest_ok_response
    end

    def rest__delete_remote()
      name = ret_non_null_request_params(:remote_module_name)
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(name)
      remote_repo = ret_remote_repo()
      remote_params = {
        :repo => remote_repo,
        :module_name => remote_module_name,
        :module_namespace => remote_namespace
      }
      remote_params.merge!(:version => version) if version
      project = get_default_project()
      ComponentModule.delete_remote(project,remote_params)
      rest_ok_response 
    end

    def rest__list_remote()
      rest_ok_response ComponentModule.list_remotes(model_handle)
    end

    def rest__export()
      component_module = create_obj(:component_module_id)
      remote_repo = ret_remote_repo()
      component_module.export(remote_repo)
      rest_ok_response 
    end

    #get remote_module_info; throws an access rights usage eerror if user does not have access
    def rest__get_remote_module_info()
      component_module = create_obj(:component_module_id)
      rsa_pub_key,action = ret_non_null_request_params(:rsa_pub_key,:action)
      access_rights = ret_access_rights()
      remote_repo = ret_remote_repo()
      rest_ok_response component_module.get_remote_module_info(action,remote_repo,rsa_pub_key,access_rights)
    end

    def rest__push_to_remote_legacy()
      component_module = create_obj(:component_module_id)
      component_module.push_to_remote_deprecate()
      rest_ok_response
    end

    #### end: actions to interact with remote repo ###

    #### actions to manage workspace

    def rest__create_new_version()
      component_module = create_obj(:component_module_id)
      new_version = ret_non_null_request_params(:new_version)
      component_module.create_new_version(new_version)
      rest_ok_response
    end

    def rest__create_new_dsl_version()
      component_module = create_obj(:component_module_id)
      dsl_version = ret_non_null_request_params(:dsl_version).to_i
      format = :json
      component_module.create_new_dsl_version(dsl_version,format)
      rest_ok_response 
    end

    #### end: actions to manage workspace and promote changes from workspace to library ###

    def rest__push_to_mirror()
      component_module = create_obj(:component_module_id)
      mirror_host = ret_non_null_request_params(:mirror_host)
      component_module.push_to_mirror(mirror_host)
    end

    def rest__add_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.add_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response(:repo_manager_fingerprint => RepoManager.repo_server_ssh_rsa_fingerprint(), :repo_manager_dns => RepoManager.repo_server_dns())
    end

    def rest__remove_user_direct_access()
      rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      ComponentModule.remove_user_direct_access(model_handle_with_private_group(),rsa_pub_key)
      rest_ok_response
    end
  end
end
