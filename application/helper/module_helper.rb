module Ramaze::Helper
  module ModuleHelper
    def rest_async_response
      body = DeferrableBody.new

      # Get the headers out there asap, let the client know we're alive...
      EM.next_tick do
        request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, body]
      end


      user_object  = ::DTK::CurrentSession.new.user_object()
      ::DTK::CreateThread.defer_with_session(user_object) do
        yield(body)
        body.succeed
      end

      throw :async
    end

    def get_service_dependencies(remote_module_name, remote_namespace, version)
      remote_repo, project = ret_remote_repo(), get_default_project()
      missing_modules, required_modules = get_required_and_missing_modules(remote_repo, project, remote_module_name, remote_namespace, version)

      { :missing_modules => missing_modules, :required_modules => required_modules }
    end


    def pull_from_remote_helper(module_class)
      #TODO: need to clean this up; right now not called because of code on server; not to clean up term for :remote_repo
      Log.error("Not expecting to call pull_from_remote_helper")
      local_module_name, remote_repo = ret_non_null_request_params(:module_name, :remote_repo)
      version = ret_request_params(:version)
      project = get_default_project()

      module_class.pull_from_remote(project, local_module_name, remote_repo, version)
    end

    def install_from_dtkn_helper(module_type)
      remote_namespace,remote_module_name,version = ::DTK::Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name))
      remote_params = create_remote_params(module_type,remote_namespace,remote_module_name,version)

      local_namespace = remote_params.namespace
      local_module_name = ret_request_params(:local_module_name)||remote_params.module_name 
      project = get_default_project()
      dtk_client_pub_key = ret_request_params(:rsa_pub_key)

      do_not_raise = (ret_request_params(:do_not_raise) ? ret_request_params(:do_not_raise) : false)
      ignore_component_error = (ret_request_params(:ignore_component_error) ? ret_request_params(:ignore_component_error) : false)
      additional_message = (ret_request_params(:additional_message) ? ret_request_params(:additional_message) : false)
      local_params = ::DTK::ModuleBranch::Location::LocalParams.new(
        :module_type => module_type,
        :module_name => local_module_name,
        :version => version,
        :namespace => local_namespace
      )

      # check for missing module dependencies
      if module_type == :service_module and !do_not_raise
        #TODO: ModuleBranch::Location:  write get_required_and_missing_modules using tow params  project,remote_params
        missing_modules, required_modules = get_required_and_missing_modules(remote_params.remote_repo_base, project, remote_params._module_name, remote_params.namespace, remote_params.version)
        # return missing modules if any
        return { :missing_module_components => missing_modules } unless missing_modules.empty?
      end

      opts = {:do_not_raise=>do_not_raise, :additional_message=>additional_message, :ignore_component_error=>ignore_component_error}
      response = module_class(module_type).install(project,local_params,remote_params,dtk_client_pub_key,opts)
      return response if response[:does_not_exist]
      
      response.merge( { :namespace => remote_namespace} )
    end

    def create_remote_params(module_type,namespace,module_name,version=nil)
      ::DTK::ModuleBranch::Location::RemoteParams.new(
        :module_type => module_type,
        :module_name => module_name,
        :version => version,
        :namespace => namespace,
        :remote_repo_base => ret_remote_repo_base()
      )
    end

    def ret_config_agent_type()
      ret_request_params(:config_agent_type)|| :puppet #TODO: puppet hardwired
    end

    def ret_diffs_summary()
      json_diffs = ret_request_params(:json_diffs)
      ::DTK::Repo::Diffs::Summary.new(json_diffs &&  (!json_diffs.empty?) && JSON.parse(json_diffs))
    end

    def ret_remote_repo_base()
      (ret_request_params(:remote_repo_base)||::DTK::Repo::Remote.default_remote_repo_base()).to_sym
    end
    #TODO: deprecate below when all uses removed; 
    def ret_remote_repo()
      (ret_request_params(:remote_repo)||::DTK::Repo::Remote.default_remote_repo()).to_sym
    end

    def ret_access_rights()
      if rights = ret_request_params(:access_rights)
        ::DTK::Repo::Remote::AccessRights.convert_from_string_form(rights)
      else
        ::DTK::Repo::Remote::AccessRights::RW
      end
    end

    def ret_library_idh_or_default()
      if ret_request_params(:library_id)
        ret_request_param_id_handle(:library_id,::DTK::Library)
      else
        ::DTK::Library.get_public_library(model_handle(:library)).id_handle()
      end
    end

    private

    def module_class(module_type)
      case module_type
        when :component_module then ::DTK::ComponentModule 
        when :service_module then ::DTK::ServiceModule
        else raise ::DTK::Error.new("Unexpected module_type (#{module_type})")
      end
    end

    def get_required_and_missing_modules(remote_repo, project, remote_module_name, remote_namespace, version)
      repo_client = ::DTK::Repo::Remote.new(remote_repo)
      response = repo_client.get_remote_module_components(remote_module_name, :service_module, version, remote_namespace)
      opts = ::DTK::Opts.new(:project_idh => project.id_handle()) 
      DTK::ComponentModule.cross_reference_modules(opts, response, remote_namespace)
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
