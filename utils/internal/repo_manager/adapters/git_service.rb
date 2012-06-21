#TODO: writing now just rest access; may want direct ruby api access if repo manager on same node
module DTK
  class RepoManagerGitService < RepoManager
    def self.create(repo,branch,opts={})
      adapter_class.new(repo,branch,opts)
    end
    def self.get_repos()
      adapter_class.get_repos()
    end
   private
    r8_nested_require('git_service','rest')
    def adapter_class()
      Rest
    end
    def initialize(repo,branch,opts={})
      @branch = branch 
      @repo = repo
    end
  end
end
