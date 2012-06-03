require 'git_repo'
module R8RepoManager
  class GitBareRepo < GitRepo
    def initialize(repo_dir,branch='master')
      super
    end
  end
end
