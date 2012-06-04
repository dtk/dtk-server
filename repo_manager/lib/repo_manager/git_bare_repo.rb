require 'grit'
module R8::RepoManager
  #TODO: some of these methods wil be mobved to teh non bare repo if determined applicable
  class GitBareRepo 
    def initialize(repo_dir,branch='master')
      @repo_dir = repo_dir
      @branch = branch
      @grit_index = nil
      @grit_repo = Grit::Repo.new(repo_dir)
    end
    def read_tree()
      @grit_index = @grit_repo.read_tree(@branch)
    end
    def add_or_replace_file_content(file_path,content)
      (@grit_index||read_tree).add(file_path,content)
    end
    def commit(commit_msg)
      @grit_index.commit(commit_msg,repo.commits,nil,nil,@branch)
    end

    def write_tree()
      git_command("write-tree".to_sym)
    end

    def push()
      Git_command__push_mutex.synchronize do 
        git_command(:push,"origin", "#{@branch}:refs/heads/#{@branch}")
      end
    end
    Git_command__push_mutex = Mutex.new

   private
    def git_command(cmd,*args)
      @grit_repo.git.send(cmd, cmd_opts(),*args)
    end
    def cmd_opts()
      {:raise => true, :timeout => 60}
    end
  end
end
