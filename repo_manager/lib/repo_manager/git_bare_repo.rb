require 'git_repo'
module R8RepoManager
  #TODO: some of these methods wil be mobved to teh non bare repo if determined applicable
  class GitBareRepo 
    def initialize(repo_dir,branch='master')
      @repo_dir = repo_dir
      @branch = branch
      @index = nil
      @repo = Grit::Repo.new(repo_dir)
    end
    def read_tree()
      @index = @repo.read_tree(@branch)
    end
    def add_or_replace_file_content(file_path,content)
      (@index||read_tree).add(file_path,content)
    end
    def commit(commit_msg)
      @index.commit(commit_msg,repo.commits,nil,nil,@branch)
    end
    def write_tree()
      Dir.chdir(@repo_dir){`git write-tree`}
    end
    def push()
    end
  end
end
