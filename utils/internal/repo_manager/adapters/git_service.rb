#TODO: writing now just rest acess; may want direct ruby api access if repo manager on same node
module DTK
  class RepoManagerGitService < RepoManager
    r8_nested_require('git_service','rest')
    def self.create(repo,branch,opts={})
      Rest.new(repo,branch,opts)
    end
    private
     def initialize(repo,branch,opts={})
      @branch = branch 
      @repo = repo
     end
  end
end
