#TODO: need requires if used standalone
r8_require_common_lib('rest_client_wrapper')
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
    def list_repos()
      route = "/rest/admin/list_repos"
      response_data = get_rest_request_data(route,:raise_error => true)
      repos = response_data["repos"]
      repos.each{|repo|repo["type"] = RepoType.new(repo["type"]) if repo["type"]}
      repos
    end

    def add_user(username,rsa_pub_key,opts={})
      route = "/rest/admin/add_user"
      body = {:username => username, :rsa_pub_key => rsa_pub_key}
      [:noop_if_exists,:delete_if_exists].each do |opt_key|
        body.merge!(opt_key => true) if opts[opt_key]
      end
      post_rest_request_data(route,body,:raise_error => true)
    end

    def create_repo(username,repo_name,access_rights="R")
      route = "/rest/admin/create_repo"
      body = {:repo_name => repo_name, :username => username, :access_rights => access_rights}
      post_rest_request_data(route,body,:raise_error => true,:timeout =>30)
    end

    def set_user_rights_in_repo(username,repo_name,access_rights="R")
      route = "/rest/admin/set_user_rights_in_repo"
      body = {:repo_name => repo_name, :username => username, :access_rights => access_rights}
      post_rest_request_data(route,body,:raise_error => true)
    end

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
          raise Error.new(response.inspect)
        end
          response.data
      else
        response.data
      end
    end


    def get_rest_request_data(route,opts={})
      handle_error(opts) do 
        Common::Rest::ClientWrapper.get("#{@rest_base_url}#{route}",ret_opts(opts))
      end
    end

    def post_rest_request_data(route,body,opts={})
      handle_error(opts) do
        Common::Rest::ClientWrapper.post("#{@rest_base_url}#{route}",body,ret_opts(opts))
      end
    end

    def ret_opts(opts)
      to_merge = DefaultTimeoutOpts.keys.inject(Hash.new) do |h,k|
        opts[k] ? h.merge(k => opts[k]) : h
      end
      DefaultTimeoutOpts.merge(to_merge)
    end
    DefaultTimeoutOpts = {:timeout => 5, :open_timeout => 0.5}

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
