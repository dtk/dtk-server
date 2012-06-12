r8_require_common_lib('rest_client_wrapper')
module XYZ
  class RepoManagerGitService < RepoManager
    class Rest < self
      def get_file_content(file_asset)
        route = "/rest/repo/get_file_content"
        body = {:repo_name => @repo,:path => file_asset[:path], :branch => @branch}
        response = post_rest_request(route,body)
        if response.ok?
          response.data["content"]
        else
          Log.error(response.inspect)
          nil
        end
      end

     private
      def get_rest_request(route,opts={})
        ::R8::Common::Rest::ClientWrapper.get("#{rest_base_url()}#{route}",opts)
      end
      def post_rest_request(route,body,opts={})
        ::R8::Common::Rest::ClientWrapper.post("#{rest_base_url()}#{route}",body,opts)
      end
      def rest_base_url()
        ::R8::Config[:repo][:git_service][:rest_base_url]
      end
    end
  end
end
