module DTK
  module RepoRemoteClassMixin
    def list_remote(repo_mh)
      repos = RemoteRepoManager.get_repos()
      repos.map{|r|{:display_name => r}}
    end
  end
end
