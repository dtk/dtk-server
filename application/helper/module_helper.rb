module Ramaze::Helper
  module ModuleHelper
    include ::DTK
    def rest_async_response
      body = DeferrableBody.new

      # Get the headers out there asap, let the client know we're alive...
      EM.next_tick do
        request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, body]
      end

      user_object  = CurrentSession.new.user_object()
      CreateThread.defer_with_session(user_object) do
        yield(body)
        body.succeed
      end

      throw :async
    end

    def get_remote_module_info_helper(module_obj)
      remote_module_name = module_obj.get_field?(:display_name)
      version = ret_version()
      remote_namespace = ret_request_params(:remote_namespace)||get_existing_default_namespace?(module_obj,version)
      remote_params = remote_params_dtkn(module_obj.module_type(),remote_namespace,remote_module_name,version)

      access_rights = ret_access_rights()
      rsa_pub_key,action = ret_non_null_request_params(:rsa_pub_key,:action)
      project = get_default_project()
      module_ref_content = ret_request_params(:module_ref_content)

      module_obj.get_linked_remote_module_info(project,action,remote_params,rsa_pub_key,access_rights,module_ref_content)
    end

    def get_service_dependencies(remote_params, client_rsa_pub_key=nil)
      project = get_default_project()
      missing_modules, required_modules, dependency_warnings = ServiceModule.get_required_and_missing_modules(project, remote_params, client_rsa_pub_key)
      { :missing_modules => missing_modules, :required_modules => required_modules, :dependency_warnings => dependency_warnings }
    end

    def chmod_from_remote_helper()
      component_module = create_obj(:module_id)
      permission_selector, remote_namespace = ret_request_params(:permission_selector, :remote_module_namespace)
      client_rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)

      remote_namespace = check_remote_namespace(remote_namespace, component_module)
      repoman_client = Repo::Remote.new().repoman_client()
      repoman_client.chmod(module_type(component_module), component_module.display_name, remote_namespace, permission_selector, client_rsa_pub_key)
    end

    def chown_from_remote_helper()
      component_module = create_obj(:module_id)
      remote_namespace = ret_request_params(:remote_module_namespace)
      client_rsa_pub_key, remote_user = ret_non_null_request_params(:rsa_pub_key, :remote_user)

      remote_namespace = check_remote_namespace(remote_namespace, component_module)
      repoman_client = Repo::Remote.new().repoman_client()
      repoman_client.chown(module_type(component_module), component_module.display_name, remote_namespace, remote_user, client_rsa_pub_key)
    end

    def collaboration_from_remote_helper
      component_module = create_obj(:module_id)
      users, groups,remote_namespace = ret_request_params(:users, :groups, :remote_module_namespace)
      action, client_rsa_pub_key = ret_non_null_request_params(:action, :rsa_pub_key)

      remote_namespace = check_remote_namespace(remote_namespace, component_module)
      repoman_client = Repo::Remote.new().repoman_client()
      repoman_client.collaboration(module_type(component_module), action, component_module.display_name, remote_namespace, users, groups, client_rsa_pub_key)
    end

    def list_collaboration_from_remote_helper
      component_module = create_obj(:module_id)
      remote_namespace = ret_request_params(:remote_module_namespace)
      client_rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)

      remote_namespace = check_remote_namespace(remote_namespace, component_module)
      repoman_client = Repo::Remote.new().repoman_client()
      repoman_client.list_collaboration(module_type(component_module), component_module.display_name, remote_namespace, client_rsa_pub_key)
    end

    def pull_from_remote_helper(module_class)
      # TODO: need to clean this up; right now not called because of code on server; not to clean up term for :remote_repo
      Log.error("Not expecting to call pull_from_remote_helper")
      local_module_name, remote_repo = ret_non_null_request_params(:module_name, :remote_repo)
      version = ret_request_params(:version)
      project = get_default_project()

      module_class.pull_from_remote(project, local_module_name, remote_repo, version)
    end

    def install_from_dtkn_helper(module_type)
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name))
      remote_params = remote_params_dtkn(module_type,remote_namespace,remote_module_name,version)

      local_namespace = remote_params.namespace
      local_module_name = ret_request_params(:local_module_name)||remote_params.module_name
      project = get_default_project()
      dtk_client_pub_key = ret_request_params(:rsa_pub_key)

      do_not_raise = (ret_request_params(:do_not_raise) ? ret_request_params(:do_not_raise) : false)
      ignore_component_error = (ret_request_params(:ignore_component_error) ? ret_request_params(:ignore_component_error) : false)
      additional_message = (ret_request_params(:additional_message) ? ret_request_params(:additional_message) : false)
      local_params = local_params_dtkn(module_type,local_namespace,local_module_name,version)

      dependency_warnings = []

      # check for missing module dependencies
      if module_type == :service_module and !do_not_raise
        missing_modules, required_modules, dependency_warnings = ServiceModule.get_required_and_missing_modules(project, remote_params, dtk_client_pub_key)
        # return missing modules if any
        return { :missing_module_components => missing_modules, :dependency_warnings => dependency_warnings } unless missing_modules.empty?
      end

      opts = {:do_not_raise=>do_not_raise, :additional_message=>additional_message, :ignore_component_error=>ignore_component_error}
      response = module_class(module_type).install(project,local_params,remote_params,dtk_client_pub_key,opts)
      return response if response[:does_not_exist]

      response.merge( { :namespace => remote_namespace, :dependency_warnings => dependency_warnings } )
    end

    def publish_to_dtkn_helper(module_obj)
      client_rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      qualified_remote_name = ret_request_params(:remote_component_name)
      namespace, remote_module_name,version = Repo::Remote.split_qualified_name(qualified_remote_name)
      local_module_name = module_obj.module_name()
      # [Amar & Haris] this is temp restriction until rest of logic is properly fixed
      if local_module_name != remote_module_name
        raise ErrorUsage.new("Publish with remote module name (#{remote_module_name}) unequal to local module name (#{local_module_name}) is currently not supported.")
      end
      module_type = module_obj.module_type
      remote_params = remote_params_dtkn(module_type,namespace,remote_module_name,version)
      local_params = local_params_dtkn(module_type,namespace,local_module_name,version)
      module_obj.publish(local_params,remote_params,client_rsa_pub_key)
    end

    def local_params_dtkn(module_type,namespace,module_name,version=nil)
      ModuleBranch::Location::LocalParams::Server.new(
        :module_type => module_type,
        :module_name => module_name,
        :version => version,
        :namespace => namespace
      )
    end

    def remote_params_dtkn(module_type,namespace,module_name,version=nil)
      ModuleBranch::Location::RemoteParams::DTKNCatalog.new(
        :module_type => module_type,
        :module_name => module_name,
        :version => version,
        :namespace => namespace||default_namespace(),
        :remote_repo_base => ret_remote_repo_base()
      )
    end

    # this looks at connected remote repos to make an assessment; default_namespace() above is static
    # if this is used; it is inserted by controller method
    def get_existing_default_namespace?(module_obj,version=nil)
      linked_remote_repos = module_obj.get_linked_remote_repos(:filter => {:version => version})
      default_remote_repo = RepoRemote.ret_default_remote_repo(linked_remote_repos)
      if default_remote_repo
        Log.info("Found default namespace (#{default_remote_repo[:display_name]})")
        default_remote_repo[:repo_namespace]
      end
    end

    def ret_config_agent_type()
      ret_request_params(:config_agent_type)|| :puppet #TODO: puppet hardwired
    end

    def ret_diffs_summary()
      json_diffs = ret_request_params(:json_diffs)
      Repo::Diffs::Summary.new(json_diffs &&  (!json_diffs.empty?) && JSON.parse(json_diffs))
    end

    def ret_remote_repo_base()
      (ret_request_params(:remote_repo_base)||Repo::Remote.default_remote_repo_base()).to_sym
    end
    # TODO: deprecate below when all uses removed;
    def ret_remote_repo()
      (ret_request_params(:remote_repo)||Repo::Remote.default_remote_repo()).to_sym
    end

    def ret_access_rights()
      if rights = ret_request_params(:access_rights)
        Repo::Remote::AccessRights.convert_from_string_form(rights)
      else
        Repo::Remote::AccessRights::RW
      end
    end

    def ret_library_idh_or_default()
      if ret_request_params(:library_id)
        ret_request_param_id_handle(:library_id,Library)
      else
        Library.get_public_library(model_handle(:library)).id_handle()
      end
    end

    private

    def module_class(module_type)
      case module_type
        when :component_module then ComponentModule
        when :service_module then ServiceModule
        else raise Error.new("Unexpected module_type (#{module_type})")
      end
    end

    def module_type(component_module)
      component_module.is_a?(ComponentModule) ? :component_module : :service_module
    end

    def check_remote_namespace(remote_namespace, component_module)
      if remote_namespace.empty?
        linked_remote_repo = component_module.default_linked_remote_repo()
        remote_namespace   = linked_remote_repo ? linked_remote_repo[:repo_namespace] : nil
        raise ErrorUsage.new("Not able to find linked remote namespace, please provide one") unless remote_namespace
      end
      remote_namespace
    end


  end
end

class DeferrableBody
  include EventMachine::Deferrable

  def send(data)
    @body_callback.call data
  end

  def each(&blk)
    @body_callback = blk
  end
end
