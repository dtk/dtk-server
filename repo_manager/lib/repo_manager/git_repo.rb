require 'grit'
module R8RepoManager
  class GitRepo
    def initialize(repo_dir,branch='master')
      @repo = Grit::Repo.new(repo_dir)
      @branch = branch
    end
  end
end
