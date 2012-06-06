class R8::RepoManager::GitoliteManager
  class Repo < self
    def initialize(repo_name,branch='master')
      #updating and querying from the bare repo   
      @repo = GitRepo::ObjectAccess.new(bare_repo_dir(repo_name),branch)
    end
    
    def add_file_and_commit(file_path,content,commit_msg=nil)
      commit_context(commit_msg||"adding file #{file_path}") do
        @repo.add_or_replace_file(file_path,content)
      end
    end
    def update_file_and_commit(file_path,content,commit_msg=nil)
      commit_context(commit_msg||"updating file #{file_path}") do
        @repo.add_or_replace_file(file_path,content)
      end
    end

    def delete_file_and_commit(file_path,commit_msg=nil)
      commit_msg = "updating file #{file_path}"
      commit_context(commit_msg||"deleting file #{file_path}") do
        @repo.delete_file(content)
      end
    end

    def file_content(file_path)
      @repo.file_content(file_path)
    end

   private
    def commit_context(commit_msg,&block)
      @repo.commit_context(commit_msg,&block)
    end
  end
end
