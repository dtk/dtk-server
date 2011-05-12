require 'grit'
module XYZ
  class Repo 
    def self.get_file_content(file_asset,context={})
      get_repo(context[:implementation]).get_file_content(file_asset,context)
    end

    def self.update_file_content(file_asset,content,context={})
      get_repo(context[:implementation]).update_file_content(file_asset,content,context)
    end

    def self.push_implementation(context={})
      get_repo(context[:implementation]).push_implementation(context)
    end

    ###
    def get_file_content(file_asset,context={})
      branch_x = ret_branch(context[:project])
      branch = branch_exists?(branch_x) ? branch_x : "master"
      ret = nil
      checkout(branch) do
        ret = File.open(file_asset[:path]){|f|f.read}
      end
      ret
    end

    def update_file_content(file_asset,content,context={})
      branch = ret_branch(context[:project])
      add_branch(branch) unless branch_exists?(branch) 
      checkout(branch) do
        File.open(file_asset[:path],"w"){|f|f << content}
        #TODO: commiting because it looks like file change visible in otehr branches until commit
        #should see if we can do more efficient job using @index.add(file_name,content)
        message = "Updating #{file_asset[:path]} in #{branch}"
        git_command__add(file_asset[:path])
        git_command__commit(message)
      end
    end

    def push_implementation(context)
      branch = ret_branch(context[:project])
      git_command__push(branch)
    end

   private
    def self.get_repo(implementation)
      index = implementation[:repo] || "__top"
      CachedRepos[index] ||= get_repo_aux(index)
    end
    def self.get_repo_aux(path)
      root = R8::EnvironmentConfig::CoreCookbooksRoot
      full_path = path == "__top" ? root : "#{root}/#{path}"
      if Aux::platform_is_linux?()
        RepoLinux.new(full_path)
      elsif  Aux::platform_is_windows?()
        RepoWindows.new(full_path)
      else
        raise Error.new("platform #{Aux::platform} not treated")
      end
    end
    CachedRepos = Hash.new

    def ret_branch(project)
      #TODO: stub
      project_ref = (project||{})[:ref]
      project_ref ? "project-#{project_ref}" : "master"
    end


    attr_reader :grit_repo
    def initialize(path)
      @path = path
      @grit_repo = Grit::Repo.new(path)
      @index = @grit_repo.index #creates new object so use @index, not grit_repo
    end
 

    def checkout(branch_name,&block)
      Dir.chdir(@path) do 
        branch_name ||= "master"

        current_head = @grit_repo.head.name
        #TODO: when get index mechanisms to work subsiture cmmited out for below
        #@index.read_tree(branch_name)
        git_command__checkout(branch_name) unless current_head == branch_name
        return unless block
        yield
        unless current_head == branch_name
          git_command__checkout(current_head)
        end
      end
    end

    def branch_exists?(branch_name)
      @grit_repo.heads.find{|h|h.name == branch_name} ? true : nil
    end

    def add_branch(branch_name,start="master")
      start ||= "master"
      checkout(start)
      message = "Adding branch #{branch_name}"
      git_command__add_branch(branch_name,message,start)
    end

    def add_file(file_path,content,branch_name="master")
      message = "Adding #{file_path} to #{branch_name}"
      ret = nil
      Dir.chdir(@path) do
        File.open(file_path,"w"){|f|f << content}
        checkout(branch_name) do 
          git_command__add(file_path)
          ret = git_command__commit(message)
        end
      end  

      #TODO: new form not working
      # @index.add(file_path,content)
      # @ index.commit(message, [@grit_repo.commit(branch_name)])
      ret
    end

    def git_command()
      @grit_repo.git
    end
  end
  class RepoLinux < Repo
   private
    def git_command__checkout(branch_name)
      git_command.checkout(CmdOpts,branch_name)
    end
    def git_command__add_branch(branch_name,message,start="master")
      #TODO: check if this works when start is diffeernat than master
      #TODO: looks like this not working: @index.commit(message, [@grit_repo.commits.first], nil, nil, branch_name)
      #TODO: not taking into account message
      git_command.branch(CmdOpts,branch_name)
    end
    def git_command__add(file_path)
      @grit_repo.add(file_path)
    end
    def git_command__commit(message)
      @grit_repo.commit_index(message)
    end
    def git_command__push(branch)
      git_command.push(CmdOpts,"origin", "#{branch}:refs/heads/#{branch}")
    end
    CmdOpts = {}

  end
  class RepoWindows  < Repo
   private
    def initialize()
      raise Error.new("R8::EnvironmentConfig::GitExecutable not defined") unless defined? R8::EnvironmentConfig::GitExecutable
      @git = R8::EnvironmentConfig::GitExecutable
      super
    end
    attr_reader :git
    def git_command__checkout(branch_name)
      `#{git} checkout #{branch_name}`
    end
    def git_command__add_branch(branch_name,message,start="master")
      #TODO: check if this works when start is diffeernat than master
      #TODO: not adding message
      `#{git} branch #{branch_name}`
    end
    def git_command__add(file_path)
      `#{git} add #{file_path}`
    end
    def git_command__commit(message)
      `#{git} commit -m #{message}`
    end
    def git_command__push(branch)
      `#{git} push origin #{branch}:refs/heads/#{branch}`
    end
  end
end
