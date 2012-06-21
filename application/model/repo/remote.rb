r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
  module RepoRemoteClassMixin
    def list_remote(repo_mh)
      repos = client.get_repos()
      repos.map{|r|{:display_name => r}}
    end
   private
    def client()
      RepoManagerClient.new(::R8::Config[:repo][:remote][:rest_base_url])
    end
  end
end
