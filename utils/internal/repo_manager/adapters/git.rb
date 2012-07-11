require 'grit'
require 'fileutils'
r8_nested_require('git','manage_git_server')
module XYZ
  class RepoManagerGit < RepoManager
    extend RepoGitManageClassMixin

    def self.create_repo_clone(repo_obj,opts)
      local_repo_dir = repo_obj[:local_dir]
      repo_name = repo_obj[:repo_name]
      if File.exists?(local_repo_dir)
        if opts[:delete_if_exists]
          FileUtils.rm_rf local_repo_dir
        else
          raise Error.new("trying to create a repo (#{repo_name}) that exists already on r8 server")
        end
      end

      local_repo = create(local_repo_dir,"master",:absolute_path => true, :repo_does_not_exist => true)
      local_repo.clone_from_git_server(repo_name)
    end

    #for binding to existing local repo
    def self.create(path,branch,opts={})
      root = R8::Config[:repo][:base_directory]
      full_path = 
        if opts[:absolute_path] then path
        else (path == "__top" ? root : "#{root}/#{path}")
        end
      if Aux::platform_is_linux?()
        RepomanagerGitLinux.new(full_path,branch,opts)
      elsif  Aux::platform_is_windows?()
        RepoManagerGitWindows.new(full_path,branch,opts)
      else
        raise Error.new("platform #{Aux::platform} not treated")
      end
    end

    def self.repo_server_dns()
      @git_dns ||= R8::Config[:repo][:git][:dns]
    end

    def self.repo_url()
      @git_url ||= "#{R8::Config[:repo][:git][:server_username]}@#{repo_server_dns()}"
    end
    def repo_url()
      @git_url ||= self.class.repo_url()
    end

    def clone_from_git_server(repo_name)
      remote_repo = "#{repo_url()}:#{repo_name}"
      git_command__clone(remote_repo,@path)      
      @grit_repo = Grit::Repo.new(@path) 
      @index = @grit_repo.index #creates new object so use @index, not grit_repo
      Dir.chdir(@path) do
        git_command__commit("initial empty commit","--allow-empty")
      end
    end

    def ls_r(depth=nil,opts={})
      Dir.chdir(@path) do
        if depth.nil?
          all_paths = Dir["**/*"]
        else
          pattern = "*"
          all_paths = Array.new
          depth.times do 
            all_paths += Dir[pattern]
            pattern = "#{pattern}/*"
          end
        end
        if opts[:file_only]
          all_paths.select{|p|File.file?(p)}
        elsif opts[:directory_only]
          all_paths.select{|p|File.directory?(p)}
        else
          all_paths
        end  
      end
    end

    def get_file_content(file_asset)
      ret = nil
      checkout(@branch) do
        ret = File.open(file_asset[:path]){|f|f.read}
      end
      ret
    end

    def add_all_files()
      checkout(@branch) do
        git_command__add(".")
        message = "Adding . in #{@branch}"
        git_command__commit(message)
      end
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

    def delete_file?(file_path)
      delete_file(file_path) if File.exists?("#{@path}/#{file_path}")
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
    DiffAttributes = [:new_file,:renamed_file,:deleted_file,:a_path,:b_path,:diff]
    def diff(other_branch)
      grit_diffs = @grit_repo.diff(@branch,other_branch)
      array_diff_hashes = grit_diffs.map do |diff|
        DiffAttributes.inject(Hash.new) do |h,a|
          val = diff.send(a)
          val ?  h.merge(a => val) : h
        end
      end
      ::DTK::Repo::Diffs.new(array_diff_hashes)
    end

    def add_remote(remote_name,remote_url)
      git_command__remote_add(remote_name,remote_url)
    end

    def push_changes(remote_name="origin")
      git_command__push(@branch,remote_name)
    end

    def pull_changes(remote_name="origin")
      checkout(@branch) do
        git_command__pull(@branch,remote_name)
      end
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
    def initialize(path,branch,opts={})
      @branch = branch 
      @path = path
      unless opts[:repo_does_not_exist]
        @grit_repo = Grit::Repo.new(path) 
        @index = @grit_repo.index #creates new object so use @index, not grit_repo
      end
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
      @grit_repo ? @grit_repo.git : Grit::Git.new("")
    end
  end
  class RepomanagerGitLinux < RepoManagerGit
   private
    def git_command__clone(remote_repo,local_dir)
      git_command.clone(cmd_opts(),remote_repo,local_dir)
    end
    def git_command__checkout(branch_name)
      git_command.checkout(cmd_opts(),branch_name)
    end
    def git_command__add_branch(branch_name)
      git_command.branch(cmd_opts(),branch_name)
    end
    def git_command__add(file_path)
      git_command.add(cmd_opts(),file_path)
      #took out because could not pass in time out @grit_repo.add(file_path)
    end
    def git_command__rm(file_path)
      git_command.rm(cmd_opts(),file_path)
      #took out because could not pass in command opts @grit_repo.remove(file_path)
    end
    def git_command__commit(message,*array_opts)
      git_command.commit({},'-m',message,*array_opts)
    end

    def git_command__remote_add(remote_name,remote_url)
      git_command.remote(cmd_opts(),:add,remote_name,remote_url)
    end

    #TODO: see what other commands needs mutex and whetehr mutex across what boundaries
    Git_command__push_mutex = Mutex.new
    def git_command__push(branch_name,remote_name="origin")
      Git_command__push_mutex.synchronize do 
        git_command.push(cmd_opts(),remote_name,"#{branch_name}:refs/heads/#{branch_name}")
      end
    end
    def git_command__pull(branch_name,remote_name="origin")
      git_command.pull(cmd_opts(),remote_name,branch_name)
    end

    def git_command__merge(branch_to_merge_from)
      git_command.merge(cmd_opts(),branch_to_merge_from)
    end

    def git_command__delete_local_branch(branch_name)
      git_command.branch(cmd_opts(),"-D",branch_name)
    end
    def git_command__delete_remote_branch(branch_name)
      git_command.push(cmd_opts(),"origin",":refs/heads/#{branch_name}")
    end
    def cmd_opts()
      {:raise => true, :timeout => 60}
    end
  end
  class RepoManagerGitWindows  < RepoManagerGit
   private
    def initialize(full_path,branch,opts={})
      raise Error.new("R8::EnvironmentConfig::GitExecutable not defined") unless defined? R8::EnvironmentConfig::GitExecutable
      @git = R8::EnvironmentConfig::GitExecutable
      super(full_path,branch,opts)
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
