module R8::RepoManager::GitoliteManager
  class Repo
    def initialize(repo_name,branch)
      @repo = GitRepo::ObjectAccess.new(repo_dir(repo_name),branch)
    end
   private
    #updating directy the bare repo
    def repo_dir(repo_name)
    end
  end
end
