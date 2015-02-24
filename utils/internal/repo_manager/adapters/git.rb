# TODO: replace as many git checkout calls with eitehr qualified calss raw object model ops taht work in both clone and bare repos
require 'grit'
require 'fileutils'
r8_nested_require('git','manage_git_server')

Grit.debug = R8::Config[:grit][:debug]
Grit::Git.git_timeout = R8::Config[:grit][:git_timeout]
Grit::Git.git_max_size = R8::Config[:grit][:git_max_size]

module DTK
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
      local_repo = create_without_branch(local_repo_dir,:absolute_path => true, :repo_does_not_exist => true)
      local_repo.create_local_repo(repo_name,opts)
      if create_branch = opts[:create_branch]
        opts_add_branch = {:empty=>true}.merge(Aux.hash_subset(opts,[:copy_files]))
        if opts[:push_created_branch]
          local_repo.add_branch_and_push?(create_branch,opts_add_branch)
        else
          local_repo.add_branch?(create_branch,opts_add_branch)
        end
      end
    end

    # for binding to existing local repo
    def self.create(path,branch,opts={})
      full_path = repo_full_path(path,opts)
      if Aux::platform_is_linux?()
        RepomanagerGitLinux.new(full_path,branch,opts)
      else
        raise Error.new("platform #{Aux::platform} not treated")
      end
    end
    def self.create_without_branch(path,opts={})
      branch = nil
      create(path,branch,opts)
    end
    private_class_method :create_without_branch

    def self.repo_full_path(path,opts={})
      if opts[:absolute_path]
        path
      else
        @root ||= R8::Config[:repo][:base_directory]
        (path == "__top" ? @root : "#{@root}/#{path}")
      end
    end

    def self.repo_server_dns()
      @git_dns ||= R8::Config[:repo][:git][:dns]
    end

    def self.repo_server_ssh_rsa_fingerprint()
      return @ssh_rsa_fingerprint if @ssh_rsa_fingerprint
      unless R8::Config[:git_server_on_dtk_server]
        raise Error.new("Not implemented yet: repo_server_fingerprint when R8::Config[:git_server_on_dtk_server] is not true")
      end
      @ssh_rsa_fingerprint ||= `ssh-keyscan -H -t rsa #{repo_server_dns()}`
    end

    #
    # Returns boolean indicating if remote git url exists
    #
    def self.git_remote_exists?(remote_url)
      git_object = Grit::Git.new('')

      !git_object.native('ls-remote',{},remote_url).empty?
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

    def create_local_repo(repo_name,opts={})
      remote_repo = "#{repo_url()}:#{repo_name}"
      git_command__clone(remote_repo,@path)
      @grit_repo = Grit::Repo.new(@path)
      unless opts[:donot_create_master_branch]
        git_command__empty_commit()
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

    def get_file_content(file_asset,opts={})
      checkout(@branch) do
        if opts[:no_error_if_not_found]
          unless File.exists?(file_asset[:path])
            return nil
          end
        end
        File.open(file_asset[:path]){|f|f.read}
      end
    end

    def move_content(source, destination, branch = nil)
      branch ||= @branch
      checkout(branch) do
        git_command__mv(source, destination)
      end
    end

    def add_all_files(branch=nil)
      branch ||= @branch
      checkout(branch) do
        git_command__add(".")
        message = "Adding . in #{branch}"
        commit(message)
      end
    end

    def add_file(file_asset,content,commit_msg=nil)
      ret = false
      content ||= String.new
      checkout(@branch) do
        path = file_asset[:path]
        recursive_create_dir?(path)
        File.open(path,"w"){|f|f << content}
        # TODO: commiting because it looks like file change visible in otehr branches until commit
        commit_msg ||= "Adding #{path} in #{@branch}"
        git_command__add(path)
        # diff(nil) looks at diffs rt to the working dir
        unless diff(nil).ret_summary().no_diffs?()
          commit(commit_msg)
          ret = true
        end
      end
      ret
    end

    def delete_file?(file_path,opts={})
       delete_tree?(:file,file_path,opts)
    end
    def delete_file(file_path,opts={})
      delete_tree(:file,file_path,opts)
    end
    def delete_directory?(dir,opts={})
       delete_tree?(:directory,dir,opts)
    end
    def delete_directory(dir,opts={})
      delete_tree(:directory,dir,opts)
    end
    def delete_tree?(type,tree_path,opts={})
      ret = nil
      checkout(@branch) do
        ret = File.exists?(full_path(tree_path))
        delete_tree(type,tree_path,opts.merge(:no_checkout=>true)) if ret
      end
      ret
    end
    def delete_tree(type,path,opts={})
      if opts[:no_checkout]
        delete_tree__body(type,path,opts)
      else
        checkout(@branch) do
          delete_tree__body(type,path,opts)
        end
      end
    end
    def delete_tree__body(type,path,opts={})
      message = "Deleting #{path} in #{@branch}"
      case type
        when :file then git_command__rm(path)
         when :directory then git_command__rm_r(path)
         else raise Error.new("Unexpected type (#{type})")
      end
      commit(message)
      if opts[:push_changes]
        push_changes()
      end
    end
    private :delete_tree__body

    def update_file_content(file_asset,content)
      checkout(@branch) do
        File.open(file_asset[:path],"w"){|f|f << content}
        # TODO: commiting because it looks like file change visible in otehr branches until commit
        message = "Updating #{file_asset[:path]} in #{@branch}"
        git_command__add(file_asset[:path])
        commit(message)
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
      a_sha = branch_sha(@branch)
      b_sha = branch_sha(other_branch)
      Repo::Diffs.new(array_diff_hashes,a_sha,b_sha)
    end

    def branch_sha(branch)
      if branch
        if ref = ref_matching_branch_name?(:local,branch)
          ref.commit.id
        end
      end
    end
    private :branch_sha

    # TODO: would like more efficient way of doing this as opposed to below which first produces object with full diff as opposed to summary
    def any_diffs?(ref1,ref2)
      not @grit_repo.diff(ref1,ref2).empty?
    end

    def get_diffs(ref1,ref2)
      @grit_repo.diff(ref1,ref2)
    end

    # returns :no_change, :changed, :merge_needed
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

    # returns :no_change, :changed, :merge_needed
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

    def hard_reset_to_branch(branch_to_reset_from)
      checkout(@branch) do
        git_command__hard_reset(branch_to_reset_from)
        push_changes(:force=>true)
      end
    end

    def initial_sync_with_remote_repo(remote_name,remote_url,remote_branch,opts={})
      add_remote?(remote_name,remote_url)

      # create branch with history from remote and not merge
      git_command__create_empty_branch(@branch)
      pull_changes(remote_name,remote_branch)

      # push to local
      push_changes()
    end

    def pull_from_remote_repo(remote_name,remote_url,remote_branch)
      add_remote?(remote_name,remote_url)
      pull_changes(remote_name,remote_branch)
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
      # TODO: may be way to do this in one step with rename
      # update": there is:  git remote set-url [--push] <name> <newurl> [<oldurl>]
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

    def branch_head_sha()
      @grit_repo.commit(@branch).id
    end

    # returns :equal, :local_behind, :local_ahead, or :branchpoint
    # type can be :remote_branch or :local_branch
    def ret_merge_relationship(type,ref,opts={})
      if (type == :remote_branch and opts[:fetch_if_needed])
        # TODO: this fetches all branches on the remote; see if anyway to just fetch a specfic branch
        # ref will be of form remote_name/branch
        git_command__fetch(ref.split("/").first)
      end

      other_sha = sha_matching_branch_name(type,ref)
      local_sha = sha_matching_branch_name(:local_branch,@branch)
      ret_sha_relationship(local_sha,other_sha)
    end

    # returns :equal, :local_behind, :local_ahead, or :branchpoint
    def ret_sha_relationship(local_sha,other_sha)
      if other_sha == local_sha
        :equal
      else
        # shas can be different but  they can have same content so do a git diff
        unless any_diffs?(local_sha,other_sha)
          return :equal
        end
        # TODO: see if missing or mis-categorizing any condition below
        if git_command__rev_list_contains?(local_sha,other_sha) then :local_ahead
        elsif git_command__rev_list_contains?(other_sha,local_sha) then :local_behind
        else :branchpoint
        end
      end
    end

    def is_different_than_remote?(remote_name, remote_url, remote_branch)
      add_remote?(remote_name,remote_url)
      # TODO: dont think this is rescue needed any more because of the c
      # If fails to fetch remote, do initial sync to load remote repo name and try to fetch remote again
      begin
        git_command__fetch(remote_name)
      rescue Exception => e
        initial_sync_with_remote_repo(remote_name,remote_url,remote_branch)
        git_command__fetch(remote_name)
      end

      remote_sha = sha_matching_branch_name(:remote,"#{remote_name}/#{remote_branch}")
      local_sha = sha_matching_branch_name(:local,@branch)

      if remote_sha == local_sha
        true
      else
        !any_diffs?(local_sha,remote_sha)
      end
    end

    def get_remote_diffs(remote_name, remote_url, remote_branch)
      add_remote?(remote_name,remote_url)
      # TODO: dont think this is rescue needed any more because of the c
      # If fails to fetch remote, do initial sync to load remote repo name and try to fetch remote again
      begin
        git_command__fetch(remote_name)
      rescue Exception => e
        initial_sync_with_remote_repo(remote_name,remote_url,remote_branch)
        git_command__fetch(remote_name)
      end

      remote_sha = sha_matching_branch_name(:remote,"#{remote_name}/#{remote_branch}")
      local_sha = sha_matching_branch_name(:local,@branch)

      get_diffs(remote_sha, local_sha)
    end

    def get_local_branches_diffs(repo_name, module_branch, base_branch, workspace_branch)
      base_sha  = sha_matching_branch_name(:remote,"origin/#{base_branch.to_s}")
      local_sha = sha_matching_branch_name(:local,workspace_branch)
      get_diffs(local_sha, base_sha)
    end

    def push_changes(opts={})
      git_command__push(@branch,opts[:remote_name],opts[:remote_branch],opts)
    end

    def pull_changes(remote_name=nil,remote_branch=nil)
      # note: even though generated git comamdn hash --git-dor set, need to chdir
      Dir.chdir(@path) do
        git_command__pull(@branch,remote_branch||@branch,remote_name)
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

    def add_branch_and_push?(new_branch,opts={})
      add_branch?(new_branch,opts)
      checkout(new_branch) do
        git_command__push(new_branch)
      end
    end

    def add_branch?(new_branch,opts={})
      unless get_branches().include?(new_branch)
        # if :copy_files; do it here and not in add_branch
        add_branch(new_branch,opts.merge(:copy_files=>nil))
      end
      if copy_files_info = opts[:copy_files]
        copy_and_add_all_files(new_branch,copy_files_info)
      end
    end
    def add_branch(new_branch,opts={})
      if opts[:empty]
        git_command__create_empty_branch(new_branch)
        git_command__empty_commit()
      else
        checkout(@branch) do
          git_command__add_branch(new_branch)
        end
      end
      if copy_files_info = opts[:copy_files]
        copy_and_add_all_files(new_branch,copy_files_info)
      end
    end

    def copy_and_add_all_files(branch,copy_files_info)
      source_dir = copy_files_info[:source_directory]
      FileUtils.cp_r("#{source_dir}/.",@path)
      Log.info("Copied files from temp Puppet Forge directory #{source_dir} to #{@path}")
      add_all_files(branch)
    end
    private :copy_and_add_all_files

    # deletes both local and remote branch
    def delete_branch(remote_name=nil)
      if @branch != current_branch()
        delete_branch_aux(remote_name)
      else
        # need to checkout to some other branch since on branch taht is being deleted
        unless other_branch = get_branches().find{|br|br != @branch}
          raise Error.new("Cannot delete the last remanining branch (#{@branch})")
        end
        checkout(other_branch) do
          delete_branch_aux(remote_name)
        end
      end
    end
    def delete_branch_aux(remote_name=nil)
      git_command__delete_local_branch?(@branch)
      git_command__delete_remote_branch?(@branch,remote_name)
    end
    private :delete_branch_aux

    def get_branches()
      @grit_repo.branches.map{|b|b.name}
    end

    def self.get_branches(repo)     #TODO: deprecate
      path = "#{R8::Config[:repo][:base_directory]}/#{repo}"
      Grit::Repo.new(path).branches.map{|b|b.name}
    end

    def ret_config_keys()
      ::Grit::Config.new(@grit_repo).keys
    end

    def ret_config_key_value(key)
      ::Grit::Config.new(@grit_repo).fetch(key)
    end

    def set_config_key_value(key,value)
      ::Grit::Config.new(@grit_repo)[key] = value
    end

   private
    attr_reader :grit_repo
    def initialize(path,branch,opts={})
      @branch = branch
      @path = path
      unless opts[:repo_does_not_exist]
        @grit_repo = Grit::Repo.new(path)
      end
    end

    def current_branch()
      @grit_repo.head.name
    end

    # type is :local/:local_branch or :remote/:remote_branch
    def sha_matching_branch_name(type, branch_name)
      ref_matching_branch_name(type,branch_name).commit.id
    end

    def ref_matching_branch_name(type, branch_name)
      ref_matching_branch_name?(type,branch_name) ||
        raise(Error.new("Cannot find #{type} branch (#{branch_name})"))
    end

    def ref_matching_branch_name?(type, branch_name)
      refs =
        case type
          when :local,:local_branch then @grit_repo.heads
          when :remote,:remote_branch then @grit_repo.remotes
          else raise Error.new("Illegal branch type (#{type})")
        end
      refs.find{|r|r.name == branch_name}
    end

    MutexesForRepos = Hash.new

    def checkout(branch_name, &block)
      ret = nil
      # TODO: add garbage collection of these mutexs
      mutex = MutexesForRepos[@path] ||= Mutex.new
      ret = nil
      mutex.synchronize do
        Dir.chdir(@path) do
          current_head = current_branch()
          git_command__checkout(branch_name) unless current_head == branch_name
          return ret unless block
          ret = yield
          unless current_head == branch_name
            git_command__checkout(branch_name)
          end
        end
      end
      ret
    end

    def git_command__empty_commit()
      commit("initial empty commit","--allow-empty")
    end

    def commit(message, *array_opts)
      Dir.chdir(@path) do
        set_author?()
        git_command.commit(cmd_opts(),'-m',message,*array_opts)
      end
    end

    def default_remote_name()
      "origin"
    end

    # sets author if not set already for repo
    def set_author?(name=nil,email=nil)
      return if @author_set
      name ||= default_author_name()
      email ||= default_author_email()
      set_config_key_value('user.name',name)
      set_config_key_value('user.email',email)
    end

    def default_author_name()
      @default_author_name ||= Common::Aux.running_process_user()
    end
    def default_author_email()
      "#{default_author_name()}@reactor8.com"
    end

    def branch_exists?(branch_name)
      ref_matching_branch_name?(:local,branch_name) ? true : nil
    end

    def remote_branch_exists?(branch_name,remote_name=nil)
      remote_name ||= default_remote_name()
      qualified_branch_name = "#{remote_name}/#{branch_name}"
      ref_matching_branch_name?(:remote,qualified_branch_name) ? true : nil
    end

    def git_command()
      # TODO: not sure why this does not work:
      # GitCommand.new(@grit_repo ? @grit_repo.git : Grit::Git.new(""))
      # only thing losing with below is visbility into failure on clone commands (where @grit_repo.nil? is true)
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
          # e.err empty is being interpretad as no error
          if e.err.nil? or e.err.empty?
            Log.info("Grit non zero exit status #{e.exitstatus} but grit err field is empty for command='#{e.command}'")
          else
            # write more info to server log, but to client return user friendly message
            Log.info("Grit error: #{e.err} exitstatus=#{e.exitstatus}; command='#{e.command}'")
            error_msg = "Grit error: #{e.err.strip()}"
            raise ErrorUsage.new(error_msg)
          end
         rescue => e
          raise e
        end
      end
      def respond_to?(name)
        !!(@grit_git.respond_to?(name) || super)
      end
    end

    def full_path(relative_path)
      "#{@path}/#{relative_path}"
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
    def git_command__create_empty_branch(branch_name)
      git_command.symbolic_ref(cmd_opts(),"HEAD","refs/heads/#{branch_name}")
    end
    def git_command__add(file_path)
      # put in -f to avoid error being thrown if try to add an ignored file
      git_command.add(cmd_opts(),file_path,"-f")
      # took out because could not pass in time out @grit_repo.add(file_path)
    end
    def git_command__rm(file_path)
      # git_command.rm uses form /usr/bin/git --git-dir=.. rm <file>; which does not delete the working directory file, so
      # need to use os comamdn to dleet file and just delete the file from the index
      git_command.rm(cmd_opts(),"--cached",file_path)
      FileUtils.rm_f full_path(file_path)
    end
    def git_command__rm_r(dir)
      git_command.rm(cmd_opts(),"-r","--cached",dir)
      FileUtils.rm_rf full_path(dir)
    end

    def git_command__mv(source, destination)
      require 'fileutils'
      FileUtils.mkdir_p(destination)
      git_command.mv(cmd_opts(), "#{source}/*", destination)
      git_command.add(cmd_opts(), '.')
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

    # TODO: see what other commands needs mutex and whether mutex across what boundaries
    Git_command__push_mutex = Mutex.new
    # returns sha of remote haed
    def git_command__push(branch_name,remote_name=nil,remote_branch=nil,opts={})
      ret = nil
      Git_command__push_mutex.synchronize do
        remote_name ||= default_remote_name()
        remote_branch ||= branch_name
        args = [cmd_opts(),remote_name,"#{branch_name}:refs/heads/#{remote_branch}"]
        args << '-f' if opts[:force]
        git_command.push(*args)
        remote_name = "#{remote_name}/#{remote_branch}"
        ret = sha_matching_branch_name(:remote,remote_name)
      end
      ret
    end

    def git_command__rev_list_contains?(container_sha,index_sha)
      rev_list = git_command.rev_list(cmd_opts(),container_sha)
      !rev_list.split("\n").grep(index_sha).empty?
    end

    def git_command__pull(local_branch,remote_branch,remote_name=nil)
      remote_name ||= default_remote_name()
      git_command.pull(cmd_opts(),remote_name,"#{remote_branch}:#{local_branch}")
    end

    # MOD_RESTRUCT-NEW deprecate below
    def git_command__pull__checkout_form(branch_name,remote_name=nil)
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

    def git_command__hard_reset(branch_to_reset_from)
      git_command.reset(cmd_opts(),'--hard',branch_to_reset_from)
    end

    def git_command__create_local_branch(branch_name)
      git_command.branch(cmd_opts(),branch_name)
    end
    def git_command__delete_local_branch?(branch_name)
      if get_branches().include?(branch_name)
        git_command__delete_local_branch(branch_name)
      end
    end
    def git_command__delete_local_branch(branch_name)
      git_command.branch(cmd_opts(),"-D",branch_name)
    end

    def git_command__delete_remote_branch?(branch_name,remote_name=nil)
      if remote_branch_exists?(branch_name,remote_name)
        git_command__delete_remote_branch(branch_name,remote_name)
      end
    end
    def git_command__delete_remote_branch(branch_name,remote_name)
      remote_name ||= default_remote_name()
      git_command.push(cmd_opts(),remote_name,":refs/heads/#{branch_name}")
    end
    def cmd_opts()
      {:raise => true, :timeout => 60}
    end
  end
end
