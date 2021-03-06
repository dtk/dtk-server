require 'sshkey'

module DTK
  class RepoManagerClient
    attr_reader :rest_base_url

    def initialize
      remote = ::R8::Config[:repo][:remote]
      is_ssl = remote[:secure_connection]
      @host  = remote[:host]

      @rest_base_url = "http#{is_ssl ? 's' : ''}://#{@host}:#{remote[:rest_port]}"
    end

    def self.repo_url_ssh_access(remote_repo_name, git_user = nil)
      new.repo_url_ssh_access(remote_repo_name, git_user)
    end

    def repo_url_ssh_access(remote_repo_name, git_user = nil)
      git_user ||= R8::Config[:repo][:remote][:git_user]
      "#{git_user}@#{@host}:#{remote_repo_name}"
    end

    def create_branch_instance(repo, branch, opts = {})
      BranchInstance.new(@rest_base_url, repo, branch, opts)
    end


    ###
    ##  V1 namespace methods
    #

    def list_modules(filter, client_rsa_pub_key)
      repo_user = get_approved_repouser(client_rsa_pub_key)

      response = 
        case filter[:type]
        when 'component'
          list_component_modules(CurrentSession.catalog_username, client_rsa_pub_key)
        when 'service'
          list_service_modules(CurrentSession.catalog_username, client_rsa_pub_key)

          # TODO: test and node deprecated
        when 'test'
          list_test_modules(CurrentSession.catalog_username, client_rsa_pub_key)
        when 'node'
          list_node_modules(CurrentSession.catalog_username, client_rsa_pub_key)
        else
          fail ErrorUsage.new("Provided module type '#{filter[:type]}' is not valid")
        end

      if namespace_filter = filter[:namespace]
        response.reject! { |module_info| module_info['namespace_name'] != namespace_filter }
      end

      response
    end

    def list_component_modules(username, client_rsa_pub_key)
      get_rest_request_data('/v1/component_modules/list_remote', user_params_with_fingerprint(username, client_rsa_pub_key), raise_error: true)
    end

    def list_service_modules(username, client_rsa_pub_key)
      get_rest_request_data('/v1/service_modules/list_remote', user_params_with_fingerprint(username, client_rsa_pub_key), raise_error: true)
    end

    def list_service_module_assemblies(username, client_rsa_pub_key)
      get_rest_request_data('/v1/service_modules/list_assemblies', user_params_with_fingerprint(username, client_rsa_pub_key), raise_error: true)
    end

    def list_test_modules(username, client_rsa_pub_key)
      get_rest_request_data('/v1/test_modules/list_remote', user_params_with_fingerprint(username, client_rsa_pub_key), raise_error: true)
    end

    def list_node_modules(username, client_rsa_pub_key)
      get_rest_request_data('/v1/node_modules/list_remote', user_params_with_fingerprint(username, client_rsa_pub_key), raise_error: true)
    end


    def list_module_assemblies(filter = nil, client_rsa_pub_key = nil)
      repo_user = get_approved_repouser(client_rsa_pub_key)
      list_service_module_assemblies(CurrentSession.catalog_username, client_rsa_pub_key)
    end

    def notify_tenant_ready(tenant_owner_email, tenant_owner_username)
      request_params = user_params(CurrentSession.catalog_username)
      request_params.merge!(tenant_owner_email: tenant_owner_email, tenant_owner_username: tenant_owner_username)
      post_rest_request_data('/v1/users/tenant_ready', request_params)
    end

    def chmod(type, module_name, module_namespace, permission_selector, chmod_action, client_rsa_pub_key)
      repo_user = get_approved_repouser(client_rsa_pub_key)
      request_params = {
        name: module_name,
        namespace: module_namespace,
        permission_selector: permission_selector
      }

      # url = type == :component_module ? '/v1/component_modules/chmod' : '/v1/service_modules/chmod'
      url_action = 'make_public'.eql?(chmod_action) ? '/make_public' : '/chmod'
      url        = collection_route_from_type(type: type) + url_action

      post_rest_request_data(
        url,
        request_params.merge(user_params_with_fingerprint(CurrentSession.catalog_username, client_rsa_pub_key)),
        raise_error: true
      )
    end

    def confirm_make_public(type, module_info, public_action, client_rsa_pub_key)
      repo_user = get_approved_repouser(client_rsa_pub_key)

      request_params = {
        module_info: module_info,
        public_action: public_action
      }

      url = collection_route_from_type(type: type) + '/confirm_make_public'
      post_rest_request_data(
        url,
        request_params.merge(user_params_with_fingerprint(CurrentSession.catalog_username, client_rsa_pub_key)),
        raise_error: true
      )
    end

    def chown(type, module_name, module_namespace, remote_user, client_rsa_pub_key)
      repo_user = get_approved_repouser(client_rsa_pub_key)
      request_params = {
        name: module_name,
        namespace: module_namespace,
        remote_user: remote_user
      }

      # url = type == :component_module ? '/v1/component_modules/chown' : '/v1/service_modules/chown'
      url = collection_route_from_type(type: type) + '/chown'

      post_rest_request_data(
        url,
        request_params.merge(user_params_with_fingerprint(CurrentSession.catalog_username, client_rsa_pub_key)),
        raise_error: true
      )
    end

    def collaboration(type, action, module_name, module_namespace, users, groups, client_rsa_pub_key)
      repo_user = get_approved_repouser(client_rsa_pub_key)
      request_params = {
        name: module_name,
        namespace: module_namespace,
        collaboration_action: action,
        collaboration_users: users,
        collaboration_groups: groups
      }

      # url = type == :component_module ? '/v1/component_modules/collaboration' : '/v1/service_modules/collaboration'
      url = collection_route_from_type(type: type) + '/collaboration'

      post_rest_request_data(
        url,
        request_params.merge(user_params_with_fingerprint(CurrentSession.catalog_username, client_rsa_pub_key)),
        raise_error: true
      )
    end

    def list_collaboration(type, module_name, module_namespace, client_rsa_pub_key)
      repo_user = get_approved_repouser(client_rsa_pub_key)
      request_params = {
        name: module_name,
        namespace: module_namespace
      }

      # url = type == :component_module ? '/v1/component_modules/list_collaboration' : '/v1/service_modules/list_collaboration'
      url = collection_route_from_type(type: type) + '/list_collaboration'

      response = post_rest_request_data(
        url,
        request_params.merge(user_params_with_fingerprint(CurrentSession.catalog_username, client_rsa_pub_key)),
        raise_error: true
      )
      response['collaborators']
    end

    def publish_module(params_hash, client_rsa_pub_key = nil)
      route = collection_route_from_type(params_hash)
      body = user_params_delegated_client(client_rsa_pub_key, params_hash)
      post_rest_request_data(route, body, raise_error: true, timeout: 30)
    end

    def delete_module(params_hash, client_rsa_pub_key = nil, opts = {})
      route = collection_route_from_type(params_hash) + '/delete_by_name'
      body = user_params_delegated_client(client_rsa_pub_key, params_hash)
      opts[:raise_error] = true unless opts.key?(:raise_error)
      delete_rest_request_data(route, body, opts)
    end

    def grant_user_access_to_module(params_hash, client_rsa_pub_key = nil)
      route = collection_route_from_type(params_hash) + '/grant_user_access'

      if client_rsa_pub_key
        body = user_params_delegated_client(client_rsa_pub_key, params_hash)
      else
        body = update_user_params(params_hash)
      end

      post_rest_request_data(route, body, raise_error: true)
    end

    # opts can have keys:
    #   :raise_with_error_exceptions - if non nil then array of error types not to raise
    def get_module_info?(params_hash, opts = {})
      route = collection_route_from_type(params_hash) + '/module_info'

      # default is to raise error
      if response = get_rest_request_data(route, params_hash, raise_error_with_exceptions: opts[:raise_error_with_exceptions])
        # we flatten response (due to rest code expecting flat structure)
        response.symbolize_keys!
        {}.merge(response[:repo_module]).merge(dependency_warnings: response[:dependency_warnings])
      end
    end
    def get_module_info(params_hash)
      get_module_info?(params_hash)
    end

    def get_components_info(params_hash, client_rsa_pub_key = nil)
      route = collection_route_from_type(type: params_hash[:type]) + '/component_info'
      get_rest_request_data(route, user_params_delegated_client(client_rsa_pub_key, params_hash), raise_error: true)
    end

    def get_module_assemblies_info(params_hash, client_rsa_pub_key = nil)
      route = collection_route_from_type(type: params_hash[:type]) + '/module_assemblies_info'
      get_rest_request_data(route, user_params_delegated_client(client_rsa_pub_key, params_hash), raise_error: true)
    end

    def remove_client_access(username)
      client_repo_user = get_repo_user_by_username(username)

      if client_repo_user && client_repo_user.has_repoman_direct_access?
        response = delete_user(CurrentSession.catalog_username, client_repo_user.rsa_pub_key)
        client_repo_user.update(repo_manager_direct_access: false) if response
      end

      nil
    end

    def register_catalog_user(username, email, password, first_name = nil, last_name = nil)
      response = post_rest_request_data(
          '/v1/users',
          {
            username: username,
            email: email,
            password: password,
            first_name: first_name,
            last_name: last_name,
            tenant_username: current_tenant_username,
            dtk_instance_name: dtk_instance_repo_username
          },
          raise_error: true
        )

      response
    end

    def add_client_access(client_rsa_pub_key, client_rsa_key_name, force_access = false)
      response = post_rest_request_data(
        '/v1/users/add_access',
        user_params(CurrentSession.catalog_username, client_rsa_pub_key, client_rsa_key_name, { :force_access => force_access }),
        raise_error: true
      )

      response
    end

    def create_tenant_user(username, rsa_pub_key, rsa_key_name)
      # Create Tenant
      route = '/v1/users/tenant'
      body = user_params(username, rsa_pub_key, rsa_key_name, catalog_username: CurrentSession.catalog_username)

      tenant_response = post_rest_request_data(route, body, raise_error: true)

      tenant_response
    end

    def validate_catalog_credentials!(username, password)
      response = handle_error(raise_error: true) do
        RestClientWrapper.post("#{@rest_base_url}/v1/auth/login", username: username, password: password, pre_hashed: false)
      end
    end

    ###
    ##  Legacy methods
    #

    # This is more revokew access
    def delete_user(username, rsa_pub_key)
      route = '/v1/users/remove_access'
      body = user_params(username, rsa_pub_key)
      delete_rest_request_data(route, body, raise_error: true)
    end

    ###
    ##  Legacy methods (Admin)
    #

    def set_user_rights_in_repo(username, repo_name, access_rights = 'R')
      route = '/rest/admin/set_user_rights_in_repo'
      body = user_params(username).merge(repo_name: repo_name, access_rights: access_rights)
      post_rest_request_data(route, body, raise_error: true)
    end

    # Method will check if repouser exists, if so it will check if it has direct_access_for_repoman
    # unless so it will create user
    def get_approved_repouser(ssh_rsa_pub_key)
      repo_user = get_repo_user(ssh_rsa_pub_key)

      unless repo_user[:repo_manager_direct_access]
        add_client_access(ssh_rsa_pub_key, repo_user[:username])
        repo_user.update(:repo_manager_direct_access => true)
      end

      repo_user
    end

    private

    #
    # returns collection route for specific type
    # collection route - plural
    #
    def collection_route_from_type(params_hash)
      # params_hash[:type].eql?("component") ? '/v1/component_modules' : '/v1/service_modules'
      case params_hash[:type].to_s
        when 'component', 'component_module'
          return '/v1/component_modules'
        when 'service', 'service_module'
          return '/v1/service_modules'
        when 'test', 'test_module'
          return '/v1/test_modules'
        when 'node', 'node_module'
          return '/v1/node_modules'
        else
          fail ErrorUsage.new("Provided module type '#{params_hash[:type]}' is not valid")
        end
    end

    #
    # returns member route for specific type
    # member route - singular
    #
    def member_route_from_type(params_hash)
      case params_hash[:type]
        when 'component'
          return '/v1/component_module'
        when 'service'
          return '/v1/service_module'
        when 'test'
          return '/v1/test_module'
        when 'node'
          return '/v1/node_module'
        else
          fail ErrorUsage.new("Provided module type '#{params_hash[:type]}' is not valid")
        end
    end

    UNAUTHORIZED_ERROR_CODE = 1001
    NAME_NOT_ALLOWED_CODE   = 1011
    NO_RESOURCE             = 1000

    # opts can have keys:
    #   :log_error
    #   :raise_error (default is true)
    #   :raise_error_with_exceptions; array if exists
    def handle_error(opts = {}, &rest_call_block)
      response = rest_call_block.call

      # token might be invalid or expired
      if error_code(response) == UNAUTHORIZED_ERROR_CODE
        Log.info("Auth failed (#{error_msg(response)}), creating new session ...")
        # remove repoman session_id from session obj
        session = CurrentSession.new
        session.set_repoman_session_id(nil)
        # repeat request
        response = rest_call_block.call
      end

      opts[:raise_error] = true unless opts[:raise_error].kind_of?(FalseClass)
      raise_error = opts[:raise_error] or !opts[:raise_error_with_exceptions].nil?
      if opts[:log_error]
        if response.ok?
          response.data
        else
          Log.error(response.inspect)
          {}
        end
      elsif !response.ok?
        msg  = error_msg(response)
        code = error_code(response)

        if raise_error
          if is_internal_error?(response)
            fail Error.new(msg)
          elsif code == NAME_NOT_ALLOWED_CODE
            error = ErrorUsage.new(msg)
            error.add_tag!(:raise_error)
            fail error
          elsif code == NO_RESOURCE
            if exceptions = opts[:raise_error_with_exceptions]
              return  nil if exceptions.include?(:no_resource)
            end
            error = ErrorUsage.new("Repo Manager error: #{msg}")
            error.add_tag!(:no_resource)
            fail error
          else
            fail ErrorUsage.new("Repo Manager error: #{msg}")
          end
        else
          dtk_code = dtk_code(response)

          # special case for new client where component_defs part of module can be dependency in another module
          if code == NO_RESOURCE && (dtk_code == 'warning' || dtk_code == 'not_allowed')
            fail ErrorUsage.new("Repo Manager error: #{msg}")
          else
            response.data
          end
        end
      else
        return response.data
      end
    end

    def get_repo_user(ssh_rsa_pub_key)
      fail ErrorUsage.new('Provided RSA pub key missing') if ssh_rsa_pub_key.nil?
      mh = ModelHandle.create_from_user(CurrentSession.new.get_user_object(), :repo_user)
      RepoUser.match_by_ssh_rsa_pub_key!(mh, ssh_rsa_pub_key)
    end

    def get_repo_user_by_username(username)
      fail ErrorUsage.new('Provided repo client username is missing') if username.empty?
      mh = ModelHandle.create_from_user(CurrentSession.new.get_user_object(), :repo_user)
      RepoUser.get_by_repo_username(mh, username)
    end

    def is_internal_error?(response)
      # error:: is namespace for our custom message on repoman
      result = response['errors'].find { |err| err['code'].is_a?(Fixnum) || err['code'].to_s.include?('error::') }
      result.nil?
    end

    def error_msg(response)
      errors = response['errors']
      if response.is_a?(Common::Response::Error) && errors
        if errors.first && (errors.first['code'].eql?('unavailable') || errors.first['code'].eql?('RestClient::ServiceUnavailable'))
          'The DTK Repo service is currently down for maintenance'
        else
          'The DTK Repo service is unavailable'
        end
      else
        error_detail = nil
        if errors.is_a?(Array) && errors.size > 0
          err_msgs = errors.map { |err| err['message'] }.compact
          unless err_msgs.empty?
            error_detail = err_msgs.join(', ')
          end
        end
        "#{error_detail || response.inspect}"
      end
    end

    def error_code(response)
      errors = response['errors']
      (errors.is_a?(Array) && errors.first) ? errors.first['code'] : 0
    end

    def dtk_code(response)
      errors = response['errors']
      (errors.is_a?(Array) && errors.first) ? errors.first['dtk_code'] : 0
    end

    def include_error_code?(errors, code)
      !!errors.find do |el|
        el.is_a?(Hash) && el['code'] == code
      end
    end

    RestClientWrapper = Common::Response::RestClientWrapper

    def get_rest_request_data(route, req_params, opts = {})
      handle_error(opts) do
        RestClientWrapper.get("#{@rest_base_url}#{route}", req_params, ret_opts(opts))
      end
    end

    def post_rest_request_data(route, body, opts = {})
      handle_error(opts) do
        RestClientWrapper.post("#{@rest_base_url}#{route}", body, ret_opts(opts))
      end
    end

    def delete_rest_request_data(route, body, opts = {})
      handle_error(opts) do
        RestClientWrapper.delete("#{@rest_base_url}#{route}", body, ret_opts(opts))
      end
    end

    def login_to_repoman
      unless CurrentSession.are_catalog_credentilas_set?
        err = ErrorUsage.new('Catalog credentials are not set, you can set them via account context')
        fail err.add_tag!(:raise_error)
      end

      response = handle_error(raise_error: true) do
        RestClientWrapper.post("#{@rest_base_url}/v1/auth/login", CurrentSession.catalog_credentials)
      end
      response['token']
    end

    def ret_opts(opts)
      to_merge = DefaultTimeoutOpts.keys.inject({}) do |h, k|
        opts[k] ? h.merge(k => opts[k]) : h
      end

      if R8::Config[:remote_repo][:authentication]
        to_merge = enrich_with_auth(to_merge)
      end

      DefaultTimeoutOpts.merge(to_merge)
    end

    def enrich_with_auth(opts)
      session_obj = CurrentSession.new

      unless session_obj.repoman_session_id
        token_id = login_to_repoman()
        session_obj.set_repoman_session_id(token_id)
      end
      # adding auth information
      opts.merge(headers: { 'Authorization' => "Token token=\"#{session_obj.repoman_session_id}\"" })
    end

    if R8::Config.is_development_mode?
      DefaultTimeoutOpts = { timeout: 5000, open_timeout: 0.5 }
    else
      DefaultTimeoutOpts = { timeout: 120, open_timeout: 0.5 }
    end

    def dtk_instance_repo_username
      ::DtkCommon::Aux.dtk_instance_repo_username()
    end

    def user_params(username, rsa_pub_key = nil, rsa_key_name = nil, additional_params = {})
      ret = { username: username, dtk_instance_name: dtk_instance_repo_username, tenant_name: current_tenant_username }

      rsa_pub_key ? ret.merge!(rsa_pub_key: rsa_pub_key) : ret
      rsa_key_name ? ret.merge!(rsa_key_name: rsa_key_name) : ret


      ret.merge!(additional_params)

      ret
    end

    def current_tenant_username
      "#{dtk_instance_prefix()}-dtk-instance"
    end

    def dtk_instance_prefix
      ::R8::Config[:repo][:remote][:tenant_name] || ::DTK::Common::Aux.running_process_user()
    end

    def user_params_with_fingerprint(username, client_rsa_pub_key)
      ret = user_params(username)
      ret[:user_fingerprint] = SSHKey.fingerprint(client_rsa_pub_key)
      ret
    end

    def update_user_params(params_hash)
      if params_hash[:username]
        {
          default_namespace: Namespace.default_namespace_name
        }.merge(params_hash)
      else
        params_hash
      end
    end

    def user_params_delegated_client(client_rsa_pub_key, params_hash)
      fail ErrorUsage.new('Missing client RSA pub key!') unless client_rsa_pub_key

      repo_user = get_repo_user(client_rsa_pub_key)

      params_hash[:username] = CurrentSession.catalog_username
      params_hash[:user_fingerprint] = SSHKey.fingerprint(client_rsa_pub_key)

      params_hash
    end

    # repo access
    class BranchInstance < self
      def initialize(rest_base_url, repo, branch, _opts = {})
        super(rest_base_url)
        @repo = repo
        @branch = branch
      end

      def get_file_content(file_asset)
        route = '/rest/repo/get_file_content'
        body = { repo_name: @repo, path: file_asset[:path], branch: @branch }
        response_data = post_rest_request_data(route, body, log_error: true)
        response_data['content']
      end

      def update_file_content(file_asset, content)
        route = '/rest/repo/update_file_content'
        body = { repo_name: @repo, path: file_asset[:path], branch: @branch, content: content }
        post_rest_request_data(route, body, raise_error: true)
      end
    end
  end
end
