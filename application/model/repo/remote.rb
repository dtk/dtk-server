module DTK
  module RepoRemoteMixin
    def self.list_remote(repo_mh)
      RemoteRepoManager.get_repos()
    end
  end
end
