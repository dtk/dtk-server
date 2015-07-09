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
      CreateThread.defer_with_session(user_object, Ramaze::Current::session) do
        yield(body)
        body.succeed
      end

      throw :async
    end

    def get_remote_module_info_helper(module_obj)
      remote_module_name = module_obj.get_field?(:display_name)
      namespace = module_obj.get_field?(:namespace)

      version = ret_version()
      remote_namespace = ret_request_params(:remote_namespace) || get_existing_default_namespace?(module_obj,version) || ret_request_params(:local_namespace)
      remote_params = remote_params_dtkn(module_obj.module_type(),remote_namespace,remote_module_name,version)

      access_rights = ret_access_rights()
      rsa_pub_key,action = ret_non_null_request_params(:rsa_pub_key,:action)
      project = get_default_project()
      module_ref_content = ret_request_params(:module_ref_content)

      module_obj.get_linked_remote_module_info(project,action,remote_params,rsa_pub_key,access_rights,module_ref_content)
    end

    def get_service_dependencies(module_type, remote_params, client_rsa_pub_key=nil)
      project = get_default_project()
      missing_modules, required_modules, dependency_warnings = module_class(module_type).get_required_and_missing_modules(project, remote_params, client_rsa_pub_key)
      { missing_modules: missing_modules, required_modules: required_modules, dependency_warnings: dependency_warnings }
    end

    def chmod_from_remote_helper
      component_module = create_obj(:module_id)
      permission_selector, remote_namespace, chmod_action = ret_request_params(:permission_selector, :remote_module_namespace, :chmod_action)
      client_rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)

      remote_namespace = check_remote_namespace(remote_namespace, component_module)
      repoman_client = Repo::Remote.new().repoman_client()
      repoman_client.chmod(module_type(component_module), component_module.display_name, remote_namespace, permission_selector, chmod_action, client_rsa_pub_key)
    end

    def confirm_make_public_helper
      component_module = create_obj(:module_id)
      module_info, remote_namespace, public_action = ret_request_params(:module_info, :remote_module_namespace, :public_action)
      client_rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)

      remote_namespace = check_remote_namespace(remote_namespace, component_module)
      repoman_client = Repo::Remote.new().repoman_client()
      repoman_client.confirm_make_public(module_type(component_module), module_info, public_action, client_rsa_pub_key)
    end

    def chown_from_remote_helper
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
      Log.error('Not expecting to call pull_from_remote_helper')
      local_module_name, remote_repo = ret_non_null_request_params(:module_name, :remote_repo)
      version = ret_request_params(:version)
      project = get_default_project()

      module_class.pull_from_remote(project, local_module_name, remote_repo, version)
    end

    def install_from_dtkn_helper(module_type)
      remote_namespace,remote_module_name,version = Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name))
      remote_params = remote_params_dtkn(module_type,remote_namespace,remote_module_name,version)

      local_namespace = remote_params.namespace
      local_module_name = ret_request_params(:local_module_name) || remote_params.module_name
      project = get_default_project()
      dtk_client_pub_key = ret_request_params(:rsa_pub_key)

      do_not_raise = (ret_request_params(:do_not_raise) ? ret_request_params(:do_not_raise) : false)
      skip_auto_install = (ret_request_params(:skip_auto_install) ? ret_request_params(:skip_auto_install) : false)
      ignore_component_error = (ret_request_params(:ignore_component_error) ? ret_request_params(:ignore_component_error) : false)
      additional_message = (ret_request_params(:additional_message) ? ret_request_params(:additional_message) : false)
      local_params = local_params(module_type,local_module_name,namespace: local_namespace,version: version)

      dependency_warnings = []

      # check for missing module dependencies
      if !do_not_raise
        missing_modules, required_modules, dependency_warnings = module_class(module_type).get_required_and_missing_modules(project, remote_params, dtk_client_pub_key)
        # return missing modules if any
        return { missing_module_components: missing_modules, dependency_warnings: dependency_warnings, required_modules: required_modules } if !missing_modules.empty? || (!required_modules.empty? && !skip_auto_install)
      end

      opts = {do_not_raise: do_not_raise, additional_message: additional_message, ignore_component_error: ignore_component_error}
      response = module_class(module_type).install(project,local_params,remote_params,dtk_client_pub_key,opts)
      return response if response[:does_not_exist]

      response.merge( namespace: remote_namespace, dependency_warnings: dependency_warnings )
    end

    def publish_to_dtkn_helper(module_obj)
      client_rsa_pub_key = ret_non_null_request_params(:rsa_pub_key)
      qualified_remote_name = ret_request_params(:remote_component_name)

      module_obj.update_object!(:display_name,:namespace)
      opts = {namespace: module_obj[:namespace][:display_name]}
      qualified_remote_name = module_obj[:display_name] if qualified_remote_name.to_s.empty?

      namespace, remote_module_name,version = Repo::Remote.split_qualified_name(qualified_remote_name,opts)
      local_module_name = module_obj.module_name()

      # [Amar & Haris] this is temp restriction until rest of logic is properly fixed
      if local_module_name != remote_module_name
        raise ErrorUsage.new("Publish with remote module name (#{remote_module_name}) not equal to local module name (#{local_module_name}) is currently not supported.")
      end

      module_type = module_obj.module_type
      remote_params = remote_params_dtkn(module_type,namespace,remote_module_name,version)
      namespace = module_obj.module_namespace()
      local_params = local_params(module_type,local_module_name,namespace: namespace,version: version)
      module_obj.publish(local_params,remote_params,client_rsa_pub_key)
    end

    # opts can have :version and :namespace
    def local_params(module_type,module_name,opts={})
      version = opts[:version]
      namespace = opts[:namespace] || default_local_namespace_name()
      ModuleBranch::Location::LocalParams::Server.new(
        module_type: module_type,
        module_name: module_name,
        version: version,
        namespace: namespace
      )
    end

    def remote_params_dtkn(module_type,namespace,module_name,version=nil)
      ModuleBranch::Location::RemoteParams::DTKNCatalog.new(
        module_type: module_type,
        module_name: module_name,
        version: version,
        namespace: namespace||Namespace.default_namespace_name(),
        remote_repo_base: ret_remote_repo_base()
      )
    end

    def default_local_namespace_name
      namespace_mh =  get_default_project().model_handle(:namespace)
      namespace_obj = ::DTK::Namespace::default_namespace(namespace_mh)
      namespace_obj.get_field?(:display_name)
    end

    # this looks at connected remote repos to make an assessment; default_namespace() above is static
    # if this is used; it is inserted by controller method
    def get_existing_default_namespace?(module_obj,version=nil)
      linked_remote_repos = module_obj.get_linked_remote_repos(filter: {version: version})
      default_remote_repo = RepoRemote.ret_default_remote_repo(linked_remote_repos)
      if default_remote_repo
        Log.info("Found default namespace (#{default_remote_repo[:display_name]})")
        default_remote_repo[:repo_namespace]
      end
    end

    def filter_by_namespace(object_list)
      module_namespace = ret_request_params(:module_namespace)
      return object_list if module_namespace.nil? || module_namespace.strip.empty?

      object_list.select do |el|
        if el[:namespace]
          # these are local modules and have namespace object
          module_namespace.eql?(el[:namespace][:display_name])
        else
          el[:display_name].match(/#{module_namespace}\//)
        end
      end
    end

    # returns [namespace,module_name] using pf_full_name param and module or namespace request params if they are given
    def ret_namespace_and_module_name_for_puppet_forge(pf_full_name)
      param_module_name = ret_request_params(:module_name)
      pf_namespace,pf_module_name = ::DTK::PuppetForge.puppet_forge_namespace_and_module_name(pf_full_name)
      if param_module_name && param_module_name != pf_module_name
        raise ErrorUsage.new("Install with module name (#{param_module_name}) not equal to puppet forge module name (#{pf_module_name}) is currently not supported.")
      end
      # default is to use namespace associated with puppet forge
      [ret_request_param_module_namespace?()||pf_namespace, pf_module_name]
    end

    def ret_assembly_template_idh
      assembly_template_id, subtype = ret_assembly_params_id_and_subtype()
      unless subtype == :template
        raise ::DTK::Error.new("Unexpected that subtype has value (#{subtype})")
      end
      id_handle(assembly_template_id,:assembly_template)
    end

    def ret_request_param_module_namespace?(param=:module_namespace)
      ret = ret_request_params(param)
      # TODO: remove need for this by on client side not passing empty strings when no namespace
      (ret.is_a?(String) && ret.empty?) ? nil : ret
    end

    def ret_config_agent_type
      ret_request_params(:config_agent_type)|| :puppet #TODO: puppet hardwired
    end

    def ret_diffs_summary
      json_diffs = ret_request_params(:json_diffs)
      Repo::Diffs::Summary.new(json_diffs &&  (!json_diffs.empty?) && JSON.parse(json_diffs))
    end

    def ret_remote_repo_base
      (ret_request_params(:remote_repo_base)||Repo::Remote.default_remote_repo_base()).to_sym
    end
    # TODO: deprecate below when all uses removed;
    def ret_remote_repo
      (ret_request_params(:remote_repo)||Repo::Remote.default_remote_repo()).to_sym
    end

    def ret_access_rights
      if rights = ret_request_params(:access_rights)
        Repo::Remote::AccessRights.convert_from_string_form(rights)
      else
        Repo::Remote::AccessRights::RW
      end
    end

    def ret_library_idh_or_default
      if ret_request_params(:library_id)
        ret_request_param_id_handle(:library_id,Library)
      else
        Library.get_public_library(model_handle(:library)).id_handle()
      end
    end

    protected

    def resolve_pull_from_remote(module_type)
      repo_module = create_obj(:module_id)
      opts = Opts.create?(remote_namespace?: ret_request_params(:remote_namespace))
      module_name, namespace, version = repo_module.get_basic_info(opts)
      remote_params = remote_params_dtkn(module_type,namespace,module_name,version)
      client_rsa_pub_key   = ret_request_params(:rsa_pub_key)

      get_service_dependencies(module_type, remote_params, client_rsa_pub_key)
    end

    private

    def module_class(module_type)
      case module_type.to_sym
        when :component_module then ComponentModule
        when :service_module then ServiceModule
        when :test_module then TestModule
        when :node_module then NodeModule
        else raise Error.new("Unexpected module_type (#{module_type})")
      end
    end

    def module_type(component_module)
      # component_module.is_a?(ComponentModule) ? :component_module : :service_module
      case component_module
        when ComponentModule
          return :component_module
        when ServiceModule
          return :service_module
        when TestModule
          return :test_module
        when NodeModule
          return :node_module
        else
          raise ErrorUsage.new("Module type '#{component_module}' is not valid")
        end
    end

    def check_remote_namespace(remote_namespace, component_module)
      if remote_namespace.empty?
        linked_remote_repo = component_module.default_linked_remote_repo()
        remote_namespace   = linked_remote_repo ? linked_remote_repo[:repo_namespace] : nil
        raise ErrorUsage.new('Not able to find linked remote namespace, please provide one') unless remote_namespace
      end
      remote_namespace
    end

    # override to include namespace in given calculations
    def create_obj(param, model_class=nil,extra_context=nil)
      id_or_name = ret_non_null_request_params(param)
      namespace_delimiter = ::DTK::Namespace.namespace_delimiter()
      if id_or_name.include?(namespace_delimiter)
        namespace, id_or_name = id_or_name.split(namespace_delimiter)
      end

      id_resolved = resolve_id_from_name_or_id(id_or_name, model_class, extra_context || namespace)

      create_object_from_id(id_resolved, model_class)
    end

    def get_obj(id, model_class=nil)
      create_object_from_id(id, model_class)
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
