r8_require('git_repo')
module R8::RepoManager
  class GitBareRepo  < GitRepo
    def initialize(repo_dir,branch='master')
      super
      @grit_index = @grit_repo.index
    end

    def read_tree()
      @grit_index.read_tree(@branch)
    end

    def add_or_replace_file(file_path,content)
      @grit_index.add(file_path,content)
    end

    def delete_file(file_path)
      @grit_index.delete(file_path)
    end

    def commit(commit_msg)
      @grit_index.commit(commit_msg,@grit_repo.commits,nil,nil,@branch)
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
