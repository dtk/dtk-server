require 'grit'
module R8::RepoManager
  class GitRepo
  end
end
r8_nested_require('git_repo','file_access')
r8_nested_require('git_repo','object_access')
module R8::RepoManager
  class GitRepo 
    def initialize(repo_dir,branch='master')
      @repo_dir = repo_dir
      @branch = branch
      @grit_repo = ::Grit::Repo.new(repo_dir)
    end
    def ls_r(depth=nil)
      tree_contents = tree.contents
      ls_r_aux(depth,tree_contents)
    end

    def path_exists?(path)
      not (tree/path).nil?
    end

    def file_content(path)
      tree_or_blob = tree/path
      tree_or_blob && tree_or_blob.kind_of?(::Grit::Blob) && tree_or_blob.data
    end

    def push()
      Git_command__push_mutex.synchronize do 
        git_command(:push,"origin", "#{@branch}:refs/heads/#{@branch}")
      end
    end
    Git_command__push_mutex = Mutex.new

    def pull()
      git_command(:pull,"origin",@branch)
    end

   private
    def tree()
      @grit_repo.tree(@branch)
    end

    def ls_r_aux(depth,tree_contents)
      ret = Array.new
      return ret if tree_contents.empty?
      return tree_contents.map{|tc|tc.name} if depth == 1

      tree_contents.each do |tc|
        if tc.kind_of?(::Grit::Blob)
          ret << tc.name
        else
          dir_name = tc.name
          ret += ls_r_aux(depth && depth-1,tc.contents).map{|r|"#{dir_name}/#{r}"}
        end
      end
      ret
    end

    def git_command(cmd,*args)
      @grit_repo.git.send(cmd, cmd_opts(),*args)
    end
    def cmd_opts()
      {:raise => true, :timeout => 60}
    end

  end
end
