require 'grit'
module XYZ
  class Repo 
    def self.get_file_content(file_asset,context={})
      get_repo(file_asset).get_file_content(file_asset,context)
    end

    def self.update_file_content(file_asset,content,context={})
      get_repo(file_asset).update_file_content(file_asset,content,context)
    end

    def get_file_content(file_asset,context={})
      repo_path_x = ret_repo_path(context)
      repo_path = branch_exists?(repo_path_x) ? repo_path_x : "master"
      ret = nil
      checkout(repo_path) do
        ret = File.open(file_asset[:path]){|f|f.read}
      end
      ret
    end

    def update_file_content(file_asset,content,context={})
      repo_path = ret_repo_path(context)
      add_branch(repo_path) unless branch_exists?(repo_path) 
      checkout(repo_path) do
        File.open(file_asset[:path],"w"){|f|f << content}
        #TODO: commiting because it looks like file change visible in otehr branches until commit
        #should see if we can do more efficient job using @index.add(file_name,content)
        message = "Updating #{file_asset[:path]} in #{repo_path}"
        @grit_repo.add(file_asset[:path])
        @grit_repo.commit_index(message)
      end
    end

   private
    def checkout(branch_name,&block)
      Dir.chdir(@path) do 
        branch_name ||= "master"
        @index.read_tree(branch_name)
        #TODO: when get index mechanisms to work dont need below
        current_head = @grit_repo.head.name
        git_command.checkout({},branch_name)
        return unless block
        yield
        unless current_head == branch_name
          git_command.checkout({},current_head)
        end
      end
    end

    def branch_exists?(branch_name)
      @grit_repo.heads.find{|h|h.name == branch_name} ? true : nil
    end

    def add_branch(branch_name,start="master")
      start ||= "master"
      checkout(start)
      #TODO: check if this works when start is diffeernat than master
      @index.commit("Adding branch #{branch_name}", [@grit_repo.commits.first], nil, nil, branch_name)
    end

    def ret_repo_path(context)
      #TODO: stub
      project_ref = (context[:project]||{})[:ref]
      project_ref ? "project-#{project_ref}" : "master"
    end

    attr_reader :grit_repo
    def initialize(path)
      @path = path
      @grit_repo = Grit::Repo.new(path)
      @index = @grit_repo.index #creates new object so use @index, not grit_repo
    end
    #TODO stubbed; should use context info in file asset id_handle to determine which repo to use
    def self.get_repo(file_asset)
      CachedRepo
    end
    CachedRepo = self.new(R8::EnvironmentConfig::CoreCookbooksRoot)
 
    def add_file(file_name,content,branch_name="master")
      message = "Adding #{file_name} to #{branch_name}"
      ret = nil
      Dir.chdir(@path) do
        File.open(file_name,"w"){|f|f << content}
        checkout(branch_name) do 
          @grit_repo.add(file_name)
          ret = @grit_repo.commit_index(message)
        end
      end  

      #TODO: new form not working
      # @index.add(file_name,content)
      # @ index.commit(message, [@grit_repo.commit(branch_name)])
      ret
    end

    def git_command()
      @grit_repo.git
    end
  end
end
