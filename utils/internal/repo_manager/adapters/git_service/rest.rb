r8_require_common_lib('rest_client_wrapper')
module DTK
  class RepoManagerGitService < RepoManager
    class Rest < self
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

      def self.get_repos()
        route = "/rest/admin/get_repos"
        response_data = get_rest_request_data(route,:raise_error => true)
        response_data["repos"]
      end

     private
      def self.handle_error(opts={},&rest_call_block)
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
        self.class.get_rest_request_data(route,opts)
      end
      DefaultTimeoutOpts = {:timeout => 1, :open_timeout => 0.1}
      def self.get_rest_request_data(route,opts={})
        handle_error(opts) do 
          Common::Rest::ClientWrapper.get("#{rest_base_url()}#{route}",DefaultTimeoutOpts)
        end
      end

      def post_rest_request_data(route,body,opts={})
        self.class.post_rest_request_data(route,body,opts)
      end
      def self.post_rest_request_data(route,body,opts={})
        handle_error(opts) do
          Common::Rest::ClientWrapper.post("#{rest_base_url()}#{route}",body,DefaultTimeoutOpts)
        end
      end

      def self.rest_base_url()
        ::R8::Config[:repo][:git_service][:rest_base_url]
      end
    end
  end
end
