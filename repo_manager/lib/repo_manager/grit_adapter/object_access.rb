module R8::RepoManager; class GritAdapter
  class ObjectAccess  < self 
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

    def create_branch(new_branch)
      if branches().include?(new_branch)
        raise Error.new("Branch (#{new_branch}) already exists")
      end
      commit_msg = "adding new branch (#{new_branch})"
      @grit_index.commit(commit_msg,@grit_repo.commits,nil,nil,new_branch)
    end

    def commit(commit_msg)
      @grit_index.commit(commit_msg,@grit_repo.commits,nil,nil,@branch)
      git_command("write-tree".to_sym)
    end

    def commit_context(commit_msg,&block)
      read_tree()
      yield
      commit(commit_msg)
    end
  end
end;end
