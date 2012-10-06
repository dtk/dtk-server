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

    def self.repo_url(repo_name=nil)
      @git_url ||= "#{R8::Config[:repo][:git][:server_username]}@#{repo_server_dns()}"
      if repo_name
        "#{@git_url}:#{repo_name}"
      else
        @git_url
      end
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
      checkout(@branch) do
        if depth.nil? or (depth.kind_of?(String) and depth == '*')
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
      checkout(@branch) do
        File.open(file_asset[:path]){|f|f.read}
      end
    end

    def add_all_files()
      checkout(@branch) do
        git_command__add(".")
        message = "Adding . in #{@branch}"
        git_command__commit(message)
      end
    end

    def add_file(file_asset,content,commit_msg=nil)
      content ||= String.new
      checkout(@branch) do
        path = file_asset[:path]
        recursive_create_dir?(path)
        File.open(path,"w"){|f|f << content}
        #TODO: commiting because it looks like file change visible in otehr branches until commit
        #should see if we can do more efficient job using @index.add(file_name,content)
        commit_msg ||= "Adding #{path} in #{@branch}"
        git_command__add(path)
        git_command__commit(commit_msg)
      end
    end

    def delete_file?(file_path)
      ret = File.exists?("#{@path}/#{file_path}")
      delete_file(file_path) if ret
      ret
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

    #returns :no_change, :changed, :merge_needed
    def fast_foward_pull(remote_branch,remote_name=nil)
      remote_name ||= default_remote_name()
      remote_ref = "#{remote_name}/#{remote_branch}"
      merge_rel = ret_merge_relationship(:remote_branch,remote_ref,:fetch_if_needed => true)
      ret = 
        case merge_rel
         when :equal then :no_change
         when :branchpoint, :local_ahead then :merge_needed
         when :local_behind then :changed  
         else raise Error.new("Unexpected merge relation (#{merge_rel})")
        end
      return ret unless ret == :changed
      checkout(@branch) do
        git_command__merge(remote_ref) #TODO: should put in semantic commit message
      end
      ret
    end

    #returns :no_change, :changed, :merge_needed
    def fast_foward_merge_from_branch(branch_to_merge_from)
      merge_rel = ret_merge_relationship(:local_branch,branch_to_merge_from)
      ret = 
        case merge_rel
         when :equal then :no_change
         when :branchpoint, :local_ahead then :merge_needed
         when :local_behind then :changed  
         else raise Error.new("Unexpected merge relation (#{merge_rel})")
        end
      return ret unless ret == :changed
      checkout(@branch) do
        git_command__merge(branch_to_merge_from) #TODO: should put in semantic commit message
        push_changes()
      end
      ret
    end

    #TODO: update to use ret_merge_relationship
    def synchronize_with_remote_repo(remote_name,remote_url,opts={})
      if remote_exists?(remote_name)
        git_command__fetch(remote_name)
      else
        add_remote(remote_name,remote_url)
      end
      pull_changes(remote_name)
      push_changes()
      remote_name
    end

    def add_remote?(remote_name,remote_url)
      unless remote_exists?(remote_name)
        add_remote(remote_name,remote_url)
      end
    end

    def add_remote(remote_name,remote_url)
      git_command__remote_add(remote_name,remote_url)
    end

    def add_or_update_remote(remote_name,remote_url)
      #TODO: may be way to do this in one step with rename
      #update": there is:  git remote set-url [--push] <name> <newurl> [<oldurl>]
      if remote_exists?(remote_name)
        remove_remote(remote_name)
      end
      add_remote(remote_name,remote_url)
    end

    def remove_remote?(remote_name)
      if remote_exists?(remote_name)
        remove_remote(remote_name)
      end
    end

    def remove_remote(remote_name)
      git_command__remote_rm(remote_name)
    end

    def remote_exists?(remote_name)
      ret_config_keys().include?("remote.#{remote_name}.url")
    end

    #returns :equal, :local_behind, :local_ahead, or :branchpoint
    #type can be :remote_branch or :local_branch
    def ret_merge_relationship(type,ref,opts={})
      if (type == :remote_branch and opts[:fetch_if_needed])
        #TODO: this fetches all branches on the remote; see if anyway to just fetch a specfic branch
        #ref will be of form remote_name/branch
        git_command__fetch(ref.split("/").first)
      end

      other_grit_ref = 
        case type
         when :remote_branch
          @grit_repo.remotes.find{|r|r.name == ref}
         when :local_branch
          @grit_repo.heads.find{|r|r.name == ref}
         else
          raise Error.new("Illegal type parameter (#{type}) passed to ret_merge_relationship") 
        end
      unless other_grit_ref
        raise Error.new("Cannot find git ref (#{ref})")
      end
      
      other_sha = other_grit_ref.commit.id
      local_sha = @grit_repo.heads.find{|r|r.name == @branch}.commit.id
      
      if other_sha == local_sha then :equal
      else
        merge_sha = git_command__merge_base(@branch,ref)
        if merge_sha == local_sha then :local_behind
         elsif merge_sha == other_sha then :local_ahead
         else :branchpoint
        end
      end
    end

    def push_changes(remote_name=nil)
      git_command__push(@branch,remote_name)
    end

    def pull_changes(remote_name=nil)
      checkout(@branch) do
        git_command__pull(@branch,remote_name)
      end
    end

    def rebase_from_remote(remote_name=nil)
       checkout(@branch) do
        git_command__rebase(@branch,remote_name)
      end
    end

    def fetch_all()
      git_command__fetch_all()
    end

    def push_implementation()
      git_command__push(@branch)
    end

    def merge_from_branch(branch_to_merge_from)
      checkout(@branch) do
        git_command__merge(branch_to_merge_from)
      end
    end

    def add_branch_and_push_to_origin?(new_branch)
      add_branch?(new_branch)
      checkout(new_branch) do
        git_command__push(new_branch)
      end
    end

    def add_branch?(new_branch)
      unless get_branches().include?(new_branch)
        add_branch(new_branch)
      end
    end

    def add_branch(new_branch)
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

    def get_branches()
      @grit_repo.branches.map{|b|b.name}
    end

    #TODO: deprecate
    def self.get_branches(repo)
      path = "#{R8::Config[:repo][:base_directory]}/#{repo}"
      Grit::Repo.new(path).branches.map{|b|b.name}
    end

    def ret_config_keys()
      ::Grit::Config.new(@grit_repo).keys
    end

    def ret_config_key_value(key)
      ::Grit::Config.new(@grit_repo).fetch(key)
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
      ret = nil
      Dir.chdir(@path) do 
        current_head = @grit_repo.head.name
        #TODO: when get index mechanisms to work subsiture cmmited out for below
        #@index.read_tree(branch_name)
        git_command__checkout(branch_name) unless current_head == branch_name
        return ret unless block
        ret = yield
        unless current_head == branch_name
          git_command__checkout(current_head)
        end
      end
      ret
    end

    def default_remote_name()
      "origin"
    end

    def default_author()
      @default_author ||= Common::Aux.running_process_user()
    end

    def branch_exists?(branch_name)
      @grit_repo.heads.find{|h|h.name == branch_name} ? true : nil
    end
    def git_command()
      #TODO: not sure why this does not work:
      #GitCommand.new(@grit_repo ? @grit_repo.git : Grit::Git.new(""))
      #only thing losing with below is visbility into failure on clone commands (where @grit_repo.nil? is true)
      @grit_repo ? GitCommand.new(@grit_repo.git) : Grit::Git.new("")
    end

    def recursive_create_dir?(path)
      if path =~ Regexp.new("(^.+)/[^/]+$")
        dir = $1
        FileUtils.mkdir_p(dir)
      end
    end

    class GitCommand
      def initialize(grit_git)
        @grit_git=grit_git
      end
      def method_missing(name,*args,&block)
        begin
          @grit_git.send(name,*args,&block)
        rescue ::Grit::Git::CommandFailed => e
          error_msg = "Grit error: #{e.err}; exitstatus=#{e.exitstatus}; command='#{e.command}'"
          raise Error.new(error_msg)
         rescue => e
          raise e
        end
      end
      def respond_to?(name)
        !!(@grit_git.respond_to?(name) || super)
      end
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
=begin
TODO: remove
      array_opts =
        if array_opts_x.find{|opt|opt =~ /^--author/}
          array_opts_x
        else
          array_opts_x + ["--author=#{default_author()}"]
        end
=end
      git_command.commit(cmd_opts(),'-m',message,*array_opts)
    end

    def git_command__remote_add(remote_name,remote_url)
      git_command.remote(cmd_opts(),:add,remote_name,remote_url)
    end

    def git_command__remote_rm(remote_name)
      git_command.remote(cmd_opts(),:rm,remote_name)
    end

    def git_command__fetch(remote_name)
      git_command.fetch(cmd_opts(),remote_name)
    end
    def git_command__fetch_all()
      git_command.fetch(cmd_opts(),"--all")
    end

    def git_command__merge_base(ref1,ref2)
      #chomp added below because raw griot command has a cr at end of line
      git_command.merge_base(cmd_opts(),ref1,ref2).chomp
    end

    #TODO: see what other commands needs mutex and whether mutex across what boundaries
    Git_command__push_mutex = Mutex.new
    def git_command__push(branch_name,remote_name=nil)
      Git_command__push_mutex.synchronize do 
        remote_name ||= default_remote_name()
        git_command.push(cmd_opts(),remote_name,"#{branch_name}:refs/heads/#{branch_name}")
      end
    end

    def git_command__pull(branch_name,remote_name=nil)
      remote_name ||= default_remote_name()
      git_command.pull(cmd_opts(),remote_name,branch_name)
    end

    def git_command__rebase(branch_name,remote_name=nil)
      remote_name ||= default_remote_name()
      git_command.rebase(cmd_opts(),"#{remote_name}/#{branch_name}")
    end

    def git_command__merge(branch_to_merge_from)
      git_command.merge(cmd_opts(),branch_to_merge_from)
    end

    def git_command__delete_local_branch(branch_name)
      git_command.branch(cmd_opts(),"-D",branch_name)
    end
    def git_command__delete_remote_branch(branch_name)
      git_command.push(cmd_opts(),default_remote_name(),":refs/heads/#{branch_name}")
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
