require 'grit'
module R8::RepoManager
  class GitRepo 
    def initialize(repo_dir,branch='master')
      @repo_dir = repo_dir
      @branch = branch
      @grit_index = nil
      @grit_repo = Grit::Repo.new(repo_dir)
    end
    def ls_r(depth=nil)
      raise Error.new("Not impleemnted yet")
    end
  end
end
