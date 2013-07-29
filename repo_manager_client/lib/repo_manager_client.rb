#TODO: need to better unify username passed adn tenant name
r8_require_common_lib('auxiliary')
r8_require_common_lib('response')
module DTK
  #TODO: RepoType should be in common
  class RepoType < String
    def is_component_module?()
      self =~ /^component_module/
    end
    def is_service_module?()
      self =~ /^service_module/
    end
  end
  class RepoManagerClient
    def initialize(rest_base_url_or_host)
      if rest_base_url_or_host =~ /^http:/
        #input is rest_base_url
        @rest_base_url = rest_base_url_or_host
        if @rest_base_url =~ Regexp.new("^http://(.+):[0-9]+$")
          @host = $1
        elsif @rest_base_url =~ Regexp.new("^http://(.+)$")
          @host = $1
        end
      else
        #input is host
        @host = rest_base_url_or_host
        port = DefaultRestServicePort #TODO: may put in provision that this can be omitted or explicitly passed
        @rest_base_url = "http://#{@host}#{port && ":#{port.to_s}"}"
      end
    end

    def repo_url_ssh_access(remote_repo_name,git_user=nil)
      remote = ::R8::Config[:repo][:remote]
      "#{git_user||GitUser}@#{@host}:#{remote_repo_name}"
    end
    DefaultGitUser = 'git'
    DefaultRestServicePort = 7000

    def create_branch_instance(repo,branch,opts={})
      BranchInstance.new(@rest_base_url,repo,branch,opts)
    end

    #admin access
    #NOTE: mark better tht these are at git level
    def list_repos()
      route = "/rest/admin/list_repos"
      response_data = get_rest_request_data(route,:raise_error => true)
      repos = response_data["repos"]
      repos.each{|repo|repo["type"] = RepoType.new(repo["type"]) if repo["type"]}
      repos
    end

    def create_repo(username,repo_name,access_rights="R")
      route = "/rest/admin/create_repo"
      body = user_params(username).merge(:repo_name => repo_name, :access_rights => access_rights)
      post_rest_request_data(route,body,:raise_error => true,:timeout =>30)
    end

    def add_git_user(username,rsa_pub_key,opts={})
      route = "/rest/admin/add_user"
      body =  user_params(username,rsa_pub_key)
      [:noop_if_exists,:delete_if_exists].each do |opt_key|
        body.merge!(opt_key => true) if opts[opt_key]
      end
      post_rest_request_data(route,body,:raise_error => true)
    end

    def set_user_rights_in_repo(username,repo_name,access_rights="R")
      route = "/rest/admin/set_user_rights_in_repo"
      body = user_params(username).merge(:repo_name => repo_name,:access_rights => access_rights)
      post_rest_request_data(route,body,:raise_error => true)
    end

    ### for utility/backup_repo_manager.rb
    def get_server_dtk_username()
      route = "/rest/admin/server_dtk_username"
      get_rest_request_data(route,:raise_error => true)["dtk_username"]
    end

    def get_ssh_rsa_pub_key()
      route = "/rest/admin/server_ssh_rsa_pub_key"
      get_rest_request_data(route,:raise_error => true)["rsa_pub_key"]
    end

    def update_ssh_known_hosts(remote_host)
      route = "/rest/admin/update_ssh_known_hosts"
      body = {:remote_host => remote_host}
      post_rest_request_data(route,body,:raise_error => true)
    end

    ## system access
    #required keys: [:username,:repo,:type]
    #optional keys: [::namespace,access_rights,:noop_if_exists]
    def create_module(params_hash)
      route = "/rest/system/module/create"
      body = defaults_for_create_module().merge(update_user_params(params_hash))
      post_rest_request_data(route,body,:raise_error => true,:timeout =>30)
    end

    def defaults_for_create_module()
      {:tenant_name => default_tenant_name(),:access_rights => "R"}
    end
    private :defaults_for_create_module

    #keys: [:name,namespace,:type,:id]
    #constraints :id or (:name, :namespace, and :type)
    def delete_module(params_hash)
      route = "/rest/system/module/delete"
      body = {:tenant_name => default_tenant_name()}.merge(params_hash)
      post_rest_request_data(route,body,:raise_error => true)
    end

    def default_tenant_name()
      dtk_instance_repo_username()
    end
    private :default_tenant_name

    #keys: [:name,namespace,:type,:id]
    #constraints :id or (:name, :namespace, and :type)
    def get_module_info(params_hash)
      route = "/rest/system/module/info"
      post_rest_request_data(route,params_hash,:raise_error => true)
    end

    def get_components_info(params_hash)
      route = "/rest/system/module/component_info"
      post_rest_request_data(route, params_hash, :raise_error => true)
    end


    def list_modules(filter=nil)
      route = "/rest/system/module/list"
      body = (filter ? {:filter => filter} : {})
      post_rest_request_data(route,body,:raise_error => true)
    end

    #require_keys => [:name,namespace,:type,username,accesss_rights]
    def grant_user_access_to_module(params_hash)
      route = "/rest/system/module/grant_user_access"
      body = update_user_params(params_hash)
      post_rest_request_data(route,body,:raise_error => true)
    end

    def create_user(username,rsa_pub_key,opts={})
      route = "/rest/system/user/create"
      body = user_params(username,rsa_pub_key)
      [:update_if_exists].each do |opt_key|
        body.merge!(opt_key => true) if opts[opt_key]
      end
      post_rest_request_data(route,body,:raise_error => true)
    end

    def list_users()
      route = "/rest/system/user/list"
      body = {}
      post_rest_request_data(route,body,:raise_error => true)
    end

=begin
#TODO: this needs fixing up
    #TODO: does not work if user has access right; so shoudl fix on repo manager and allow names
    def delete_user(user_id_or_name) 
      #TODO: this is temporary until enable repo manager to take name or id or we cache id
      if user_id_or_name.kind_of?(Fixnum)
        delete_user_given_id(user_id_or_name)
      else
        user_info = list_users()
        unless matching_user = user_info.find{|r|r["username"] == user_id_or_name}
          raise ErrorUsage.new("User (#{user_id_or_name} does not exist")
        end
        delete_user_given_id(matching_user["id"])
      end
    end

    def delete_user_given_id(user_id)
      route = "/rest/system/user/delete"
      body = {:id => user_id}
      post_rest_request_data(route,body,:raise_error => true)
    end
=end

   private
    def handle_error(opts={},&rest_call_block)
      response = rest_call_block.call
      if opts[:log_error]
        if response.ok?
          response.data
        else
          Log.error(response.inspect)
          {}
        end
      elsif opts[:raise_error]
        unless response.ok?
          error_msg = response.error_message()
          if error_msg && !error_msg.empty?
            raise ErrorUsage.new(error_msg)
          else
            raise ErrorUsage.new(error_msg(response))
          end
        end
          response.data
      else
        response.data
      end
    end

    def error_msg(response)
      if response.kind_of?(Common::Response::Error) and response["errors"] 
        errors = response["errors"]
        #if include_error_code?(errors,"connection_refused") 
        "Repo Manager refused the connection; it may be down"
      else
        "Repo Manager Connection Error: #{response.inspect}"
      end
    end
    def include_error_code?(errors,code)
      !!errors.find do |el|
        el.kind_of?(Hash) and el["code"] == code
      end
    end

    RestClientWrapper = Common::Response::RestClientWrapper
    def get_rest_request_data(route,opts={})
      handle_error(opts) do 
        RestClientWrapper.get("#{@rest_base_url}#{route}",ret_opts(opts))
      end
    end

    def post_rest_request_data(route,body,opts={})
      handle_error(opts) do
        RestClientWrapper.post("#{@rest_base_url}#{route}",body,ret_opts(opts))
      end
    end

    def ret_opts(opts)
      to_merge = DefaultTimeoutOpts.keys.inject(Hash.new) do |h,k|
        opts[k] ? h.merge(k => opts[k]) : h
      end
      DefaultTimeoutOpts.merge(to_merge)
    end
    DefaultTimeoutOpts = {:timeout => 5, :open_timeout => 0.5}

    def dtk_instance_repo_username()
      ::DtkCommon::Aux::dtk_instance_repo_username()
    end

    def user_params(username,rsa_pub_key=nil)
      ret = {:username => username,:dtk_instance_name => dtk_instance_repo_username()}
      rsa_pub_key ? ret.merge(:rsa_pub_key => rsa_pub_key) : ret
    end

    def update_user_params(params_hash)
      if params_hash[:username]
        {:dtk_instance_name => params_hash[:dtk_instance_name]}.merge(params_hash)
      else
        params_hash
      end
    end

    #repo access
    class BranchInstance < self
      def initialize(rest_base_url,repo,branch,opts={})
        super(rest_base_url)
        @repo = repo
        @branch = branch
      end

      def get_file_content(file_asset)
        route = "/rest/repo/get_file_content"
        body = {:repo_name => @repo,:path => file_asset[:path], :branch => @branch}
        response_data = post_rest_request_data(route,body,:log_error => true)
        response_data["content"]
      end

      def update_file_content(file_asset,content)
        route = "/rest/repo/update_file_content"
        body = {:repo_name => @repo,:path => file_asset[:path], :branch => @branch, :content => content}
        post_rest_request_data(route,body,:raise_error => true)
      end

      def push_to_mirror(mirror_host)
        route = "/rest/repo/push_to_mirror"
        body = {:repo_name => @repo,:mirror_host => mirror_host}
        post_rest_request_data(route,body,:raise_error => true)
      end 

    end
  end
end
