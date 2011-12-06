require 'grit'
r8_nested_require('git','manage_git_server')
module XYZ
  class RepoManagerGit < RepoManager
    extend RepoGitManageClassMixin
    def self.create(path,branch,opts={})
      root = R8::Config[:repo][:base_directory]
      full_path = 
        if opts[:absolute_path] then path
        else (path == "__top" ? root : "#{root}/#{path}")
        end
      if Aux::platform_is_linux?()
        RepomanagerGitLinux.new(full_path,branch)
      elsif  Aux::platform_is_windows?()
        RepoManagerGitWindows.new(full_path,branch)
      else
        raise Error.new("platform #{Aux::platform} not treated")
      end
    end

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

    def delete_file(file_path)
      checkout(@branch) do
        message = "Deleting #{file_path} in #{@branch}"
        git_command__rm(file_path)
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

    def push_changes()
      git_command__push(@branch)
    end

    def pull_changes()
      git_command__pull(@branch)
    end

    def push_implementation()
      git_command__push(@branch)
    end

    def merge_from_branch(branch_to_merge_from)
      checkout(@branch) do
        git_command__merge(branch_to_merge_from)
      end
    end

    def clone_branch(new_branch)
      checkout(@branch) do
        git_command__add_branch(new_branch)
      end
    end

    def delete_branch()
      raise Error.new("Cannot delete master branch") if @branch == "master"
      checkout("master")
      git_command__delete_local_branch(@branch)      
      #TODO: need to make conditional on whether remote branch exists
      git_command__delete_remote_branch(@branch)      
    end

    #TODO: change so this is gotten from db to if want to put in hooks for per branch auth
    def self.get_branches(repo)
      path = "#{R8::Config[:repo][:base_directory]}/#{repo}"
      Grit::Repo.new(path).branches.map{|b|b.name}
    end

   private

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
  class RepomanagerGitLinux < RepoManagerGit
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
    def git_command__rm(file_path)
      @grit_repo.remove(file_path)
    end
    def git_command__commit(message)
      @grit_repo.commit_index(message)
    end
    def git_command__push(branch_name)
      git_command.push(CmdOpts,"origin", "#{branch_name}:refs/heads/#{branch_name}")
    end
    def git_command__pull(branch_name)
      git_command.pull(CmdOpts,"origin",branch_name)
    end

    def git_command__merge(branch_to_merge_from)
      git_command.merge(CmdOpts,branch_to_merge_from)
    end

    def git_command__delete_local_branch(branch_name)
      git_command.branch(CmdOpts,"-D",branch_name)
    end
    def git_command__delete_remote_branch(branch_name)
      git_command.push(CmdOpts,"origin",":refs/heads/#{branch_name}")
    end
    CmdOpts = {}

  end
  class RepoManagerGitWindows  < RepoManagerGit
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
