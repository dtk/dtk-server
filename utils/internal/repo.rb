require 'grit'
module XYZ
  class Repo 
    def self.get_file_content(file_asset,context)
      get_repo(context).get_file_content(file_asset)
    end

    def self.update_file_content(file_asset,content,context)
      get_repo(context).update_file_content(file_asset,content)
    end

    def self.add_file(file_asset,content,context)
      get_repo(context).add_file(file_asset,content)
    end

    def self.push_implementation(context)
      get_repo(context).push_implementation()
    end

    def self.clone_branch(context,new_branch)
      return if (R8::Config[:repo]||{})[:type] == "mock"
      get_repo(context).clone_branch(new_branch)
    end
    def self.delete(context)
      get_repo(context).delete()
    end

    def self.delete_all_branches()
      repos = nil
      Dir.chdir(R8::EnvironmentConfig::CoreCookbooksRoot) do
        repos = Dir["*"].reject{|item|File.file?(item)}
      end
      repos.each do |repo|
        get_branches(repo).each do |branch|
          next if branch == "master"
          pp "deleting branch (#{branch}) in repo (#{repo})"
          context = {
            :implementation => {
            :repo => repo,
            :branch => branch
            }
          }
          get_repo(context).delete()
        end
      end
    end

    ###
    def get_file_content(file_asset)
      ret = nil
      checkout(@branch) do
        ret = File.open(file_asset[:path]){|f|f.read}
      end
      ret
    end

    def add_file(file_asset,content)
      content ||= String.new
      checkout(@branch) do
        File.open(file_asset[:path],"w"){|f|f << content}
        #TODO: commiting because it looks like file change visible in otehr branches until commit
        #should see if we can do more efficient job using @index.add(file_name,content)
        message = "Adding #{file_asset[:path]} in #{@branch}"
        git_command__add(file_asset[:path])
        git_command__commit(message)
      end
    end

    def update_file_content(file_asset,content)
      checkout(@branch) do
        File.open(file_asset[:path],"w"){|f|f << content}
        #TODO: commiting because it looks like file change visible in otehr branches until commit
        #should see if we can do more efficient job using @index.add(file_name,content)
        message = "Updating #{file_asset[:path]} in #{@branch}"
        git_command__add(file_asset[:path])
        git_command__commit(message)
      end
    end

    def push_implementation()
      git_command__push(@branch)
    end

    def clone_branch(new_branch)
      checkout(@branch) do
        git_command__add_branch(new_branch)
      end
    end

    def delete()
      raise Error.new("Cannot delete master branch") if @branch == "master"
      checkout("master")
      git_command__delete_local_branch(@branch)      
      #TODO: need to make conditional on whether remote branch exists
      git_command__delete_remote_branch(@branch)      
    end

   private
    def self.get_repo(context)
      repo = (context[:implementation]||{})[:repo]||"__top"
      branch = (context[:implementation]||{})[:branch]
      raise Error.new("cannot find branch in context") unless branch
      CachedRepos[repo] ||= Hash.new
      CachedRepos[repo][branch] ||= get_repo_aux(repo,branch)
    end
    def self.get_repo_aux(path,branch)
      root = R8::EnvironmentConfig::CoreCookbooksRoot
      full_path = path == "__top" ? root : "#{root}/#{path}"
      if Aux::platform_is_linux?()
        RepoLinux.new(full_path,branch)
      elsif  Aux::platform_is_windows?()
        RepoWindows.new(full_path,branch)
      else
        raise Error.new("platform #{Aux::platform} not treated")
      end
    end
    CachedRepos = Hash.new

    def self.get_branches(repo)
      path = "#{R8::EnvironmentConfig::CoreCookbooksRoot}/#{repo}"
      Grit::Repo.new(path).branches.map{|b|b.name}
    end

    attr_reader :grit_repo
    def initialize(path,branch)
      @branch = branch 
      @path = path
      @grit_repo = Grit::Repo.new(path)
      @index = @grit_repo.index #creates new object so use @index, not grit_repo
    end

    def checkout(branch_name,&block)
      Dir.chdir(@path) do 
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
    def git_command()
      @grit_repo.git
    end
  end
  class RepoLinux < Repo
   private
    def git_command__checkout(branch_name)
      git_command.checkout(CmdOpts,branch_name)
    end
    def git_command__add_branch(branch_name)
      git_command.branch(CmdOpts,branch_name)
    end
    def git_command__add(file_path)
      @grit_repo.add(file_path)
    end
    def git_command__commit(message)
      @grit_repo.commit_index(message)
    end
    def git_command__push(branch_name)
      git_command.push(CmdOpts,"origin", "#{branch_name}:refs/heads/#{branch_name}")
    end
    def git_command__delete_local_branch(branch_name)
      git_command.branch(CmdOpts,"-D",branch_name)
    end
    def git_command__delete_remote_branch(branch_name)
      git_command.push(CmdOpts,"origin",":refs/heads/#{branch_name}")
    end
    CmdOpts = {}

  end
  class RepoWindows  < Repo
   private
    def initialize(full_path,branch)
      raise Error.new("R8::EnvironmentConfig::GitExecutable not defined") unless defined? R8::EnvironmentConfig::GitExecutable
      @git = R8::EnvironmentConfig::GitExecutable
      super(full_path,branch)
    end
    attr_reader :git
    def git_command__checkout(branch_name)
      `#{git} checkout #{branch_name}`
    end
    def git_command__add_branch(branch_name)
      `#{git} branch #{branch_name}`
    end
    def git_command__add(file_path)
      `#{git} add #{file_path}`
    end
    def git_command__commit(message_x)
      #TODO: looks like windows may not take spaces in message
      message = message_x.gsub(' ','-')
      `#{git} commit -m '#{message}'`
    end
    def git_command__push(branch_name)
      `#{git} push origin #{branch}:refs/heads/#{branch_name}`
    end
  end
end
