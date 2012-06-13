#TODO: writing now just rest access; may want direct ruby api access if repo manager on same node
module DTK
  class RepoManagerGitService < RepoManager
    r8_nested_require('git_service','rest')
    AdapterClass = Rest
    def self.create(repo,branch,opts={})
      AdapterClass.new(repo,branch,opts)
    end
    def self.get_repos()
      AdapterClass.get_repos()
    end
    private
     def initialize(repo,branch,opts={})
      @branch = branch 
      @repo = repo
     end
  end
end
