r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
  class RepoManagerRepoManagerClient < RepoManager
    def self.create(repo,branch,opts={})
      adapter_class.new(repo,branch,opts)
    end
    def self.get_repos()
      adapter_class.get_repos()
    end
   private
    def self.adapter_class()
      @adapter_class ||= DTK::RepoManagerClient.new(::R8::Config[:repo][:repo_manager_client][:server_rest_base_url])
    end
    def initialize(repo,branch,opts={})
      @branch = branch 
      @repo = repo
    end
  end
end
