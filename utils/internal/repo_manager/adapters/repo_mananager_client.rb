#for use when using repo manager for local repo
r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
  class RepoManagerRepoManagerClient < RepoManager
    def self.create(repo,branch,opts={})
      adapter.create_branch_instance(repo,branch,opts)
    end
    def self.list_repos()
      adapter.list_repos()
    end
   private
    def self.adapter()
      @adapter ||= DTK::RepoManagerClient.new(::R8::Config[:repo][:repo_manager_client][:server_rest_base_url])
    end
  end
end
