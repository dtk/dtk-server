module R8::RepoManager; class GitoliteManager
  class Repo < self
    #TODO: instaed may make child of GitRepo::ObjectAccess; or use missing method and send to @repo
    #but check in explicit list
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

    #'pass' all these methods to @repo
    RepoMethods = [:add_or_replace_file,:branches,:create_branch,:file_content,:ls_r,:commit_context]
    def method_missing(name,*args,&block)
      if RepoMethods.include?(name)
        @repo.send(name,*args,&block)
      else
        super
      end
    end
    def respond_to?(name)
      !!(RepoMethods.include?(name) || super)
    end

=begin
    def add_or_replace_file(file_path,content)
      @repo.add_or_replace_file(file_path,content)
    end

    def branches()
      @repo.branches()
    end
    
    def create_branch(new_branch)
      @repo.create_branch(new_branch)
    end

    def file_content(file_path)
      @repo.file_content(file_path)
    end

    def ls_r(depth=nil,opts={})
      @repo.ls_r(depth,opts)
    end

    def commit_context(commit_msg,&block)
      @repo.commit_context(commit_msg,&block)
    end
=end
  end
end;end
