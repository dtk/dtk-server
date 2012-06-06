class R8::RepoManager::GitoliteManager
  class Repo < self
    def initialize(repo_name,branch='master')
      @repo = GitRepo::ObjectAccess.new(repo_dir(repo_name),branch)
    end
   private
    #updating directly the bare repo   
    def repo_dir(repo_name)
      bare_repo_dir(repo_name)
    end
  end
end
