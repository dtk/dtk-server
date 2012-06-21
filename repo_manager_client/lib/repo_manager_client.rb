#TODO: need requires if used standalone
r8_require_common_lib('rest_client_wrapper')
module DTK
  class RepoManagerClient
    def initialize(rest_base_url)
      @rest_base_url = rest_base_url
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

    def get_repos()
      route = "/rest/admin/get_repos"
      response_data = get_rest_request_data(route,:raise_error => true)
      response_data["repos"]
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

    DefaultTimeoutOpts = {:timeout => 1, :open_timeout => 0.5}
    def get_rest_request_data(route,opts={})
      handle_error(opts) do 
        Common::Rest::ClientWrapper.get("#{@rest_base_url}#{route}",DefaultTimeoutOpts)
      end
    end

    def post_rest_request_data(route,body,opts={})
      handle_error(opts) do
        Common::Rest::ClientWrapper.post("#{@rest_base_url}#{route}",body,DefaultTimeoutOpts)
      end
    end
  end
end
