module Ramaze::Helper
  module ModuleHelper

    def rest_async_response
      body = DeferrableBody.new

      # Get the headers out there asap, let the client know we're alive...
      EM.next_tick do
        request.env['async.callback'].call [200, {'Content-Type' => 'text/plain'}, body]
      end

      ::DTK::CreateThread.defer do
        yield(body)
        body.succeed
      end

      throw :async
    end

    def import_method_helper(module_class)
      remote_namespace,remote_module_name,version = ::DTK::Repo::Remote::split_qualified_name(ret_non_null_request_params(:remote_module_name))
      local_module_name = ret_request_params(:local_module_name)||remote_module_name 
      remote_repo = ret_remote_repo()
      project = get_default_project()
      remote_params = {
        :repo => remote_repo,
        :module_namespace => remote_namespace,
        :module_name => remote_module_name,
        :version => version
      }
      local_params = {
        :module_name => local_module_name
      }

      begin
        response = module_class.import(project,remote_params,local_params)
      rescue ::DTK::ErrorUsage::DanglingComponentRefs => e
        if (module_class == ::DTK::ServiceModule && missing_modules = e.missing_module_list())
          # TODO: [Haris] temp solution until Rich agument namespaces to DSL
          return { :missing_module_components => missing_modules.collect { |v| v.merge(:namespace => remote_namespace) } }
        else
          # [Haris] Contact me if this error occurs
          Log.error "Unexpected error, missing component refs for component module! Contact Haris."
          raise e
        end
      end
      response.merge( { :namespace => remote_namespace} )
    end

    def ret_config_agent_type()
      ret_request_params(:config_agent_type)|| :puppet #TODO: puppet hardwired
    end

    def ret_diffs_summary()
      json_diffs = ret_request_params(:json_diffs)
      ::DTK::Repo::Diffs::Summary.new(json_diffs &&  (!json_diffs.empty?) && JSON.parse(json_diffs))
    end

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