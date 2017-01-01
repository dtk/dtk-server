#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# TODO: replace as many git checkout calls with either qualified calls raw object model ops taht work in both clone and bare repos
require 'grit'
require 'fileutils'
::Grit.debug = R8::Config[:grit][:debug]
::Grit::Git.git_timeout = R8::Config[:grit][:git_timeout]
::Grit::Git.git_max_size = R8::Config[:grit][:git_max_size]

module DTK; class RepoManager
  class Git < self
    require_relative('git/linux')
    require_relative('git/git_command')
    require_relative('git/mixin')
    require_relative('git/manage_git_server')

    include Mixin::FileProcessing
    include Mixin::BranchProcessing
    extend ManageGitServer::ClassMixin

    attr_reader :path
    def initialize(path, branch, opts = {})
      @branch = branch
      @path = path
      unless opts[:repo_does_not_exist]
        @grit_repo = ::Grit::Repo.new(path)
      end
    end
    private :initialize

    # opts can have keys:
    #  :delete_if_exists - Boolean (default: false)
    #  :push_created_branch  - Boolean (default: false)
    #  :donot_create_master_branch - Boolean (default: false)
    #  :create_branch  - branch to create (f non nil)
    #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
    def self.create_repo_clone(repo_obj, opts)
      local_repo_dir = repo_obj[:local_dir]
      repo_name = repo_obj[:repo_name]
      if File.exist?(local_repo_dir)
        if opts[:delete_if_exists]
          FileUtils.rm_rf local_repo_dir
        else
          fail Error.new("trying to create a repo (#{repo_name}) that exists already on r8 server")
        end
      end
      local_repo = create_without_branch(local_repo_dir, absolute_path: true, repo_does_not_exist: true)
      local_repo.create_local_repo(repo_name, opts)
      if create_branch = opts[:create_branch]
        opts_add_branch = { empty: true }
        opts_add_branch.merge!(Aux.hash_subset(opts, [:add_remote_files_info]))
        if opts[:push_created_branch]
          local_repo.add_branch_and_push?(create_branch, opts_add_branch)
        else
          local_repo.add_branch?(create_branch, opts_add_branch)
        end
      end
    end

    # for binding to existing local repo
    def self.create(path, branch, opts = {})
      full_path = repo_full_path(path, opts)
      if Aux.platform_is_linux?
        Linux.new(full_path, branch, opts)
      else
        fail Error, "platform #{Aux.platform} not treated"
      end
    end
    def self.create_without_branch(path, opts = {})
      branch = nil
      create(path, branch, opts)
    end
    private_class_method :create_without_branch

    def self.repo_full_path(path, opts = {})
      if opts[:absolute_path]
        path
      else
        @root ||= R8::Config[:repo][:base_directory]
        (path == '__top' ? @root : "#{@root}/#{path}")
      end
    end

    def self.repo_server_dns
      @git_dns ||= R8::Config[:repo][:git][:dns]
    end

    def self.repo_server_ssh_rsa_fingerprint
      return @ssh_rsa_fingerprint if @ssh_rsa_fingerprint
      unless R8::Config[:git_server_on_dtk_server]
        fail Error.new('Not implemented yet: repo_server_fingerprint when R8::Config[:git_server_on_dtk_server] is not true')
      end
      @ssh_rsa_fingerprint ||= get_tenant_rsa_key
      @ssh_rsa_fingerprint
    end

    def self.get_tenant_rsa_key
      git_port = R8::Config[:repo][:git][:port]
      result = nil
      begin
        number_of_retries ||= 3
        result = `ssh-keyscan -H -p #{git_port} #{repo_server_dns}`
        raise Exception, "Try again ssh keyscan" if result.empty?
      rescue Exception
        unless (number_of_retries -= 1).zero?
          sleep(1)
          retry
        end
        fail Error.new('Unable to retrieve usable host RSA key, aborting operation!')
      end
      result
    end

    #
    # Returns boolean indicating if remote git url exists
    #
    def self.git_remote_exists?(remote_url)
      git_object = ::Grit::Git.new('')

      !git_object.native('ls-remote', {}, remote_url).empty?
    end

    def self.repo_url(repo_name = nil)
      @git_url ||= "ssh://#{R8::Config[:repo][:git][:server_username]}@#{repo_server_dns}:#{R8::Config[:repo][:git][:port]}"
      if repo_name
        "#{@git_url}/#{repo_name}"
      else
        @git_url
      end
    end

    def repo_url
      @git_url ||= self.class.repo_url
    end

    # opts can have keys:
    #  :donot_create_master_branch - Boolean (default: false)
    def create_local_repo(repo_name, opts = {})
      remote_repo = "#{repo_url}/#{repo_name}"

      git_command__clone(remote_repo, @path)
      @grit_repo = ::Grit::Repo.new(@path)
      unless opts[:donot_create_master_branch]
        git_command__empty_commit
      end
    end

    # opts can have keys:
    #  :branch
    #  :commit_msg
    def add_all_files_and_commit(opts = {})
      branch = opts[:branch] || @branch
      checkout(branch) do
        git_command__add('.')
        message = opts[:commit_msg] || "Adding . in #{branch}"
        commit(message)
      end
    end

    def file_changed_since_specified_sha(initial_service_module_sha, path)
      diffs = diff(initial_service_module_sha)
      diffs_summary = diffs.ret_summary
      diffs_summary.file_changed?(path)
    end

    def branch_sha(branch)
      if branch
        if ref = ref_matching_branch_name?(:local, branch)
          ref.commit.id
        end
      end
    end
    private :branch_sha

    # TODO: would like more efficient way of doing this as opposed to below which first produces object with full diff as opposed to summary
    def any_diffs?(ref1, ref2)
      not @grit_repo.diff(ref1, ref2).empty?
    end

    def get_diffs(ref1, ref2)
      @grit_repo.diff(ref1, ref2)
    end

    # TODO: DTK-2795: put in pull_return_merge_relationship(remote_branch, conflict_merge_relationships, opts = {}) and have fast_foward_pull be
    # pull_return_merge_relationship((remote_branch, [:branchpoint, :local_ahead]
    #


    # returns :no_change, :changed, :merge_needed
    # opts can have keys:
    #   :force
    #   :remote_name
    #   :remote_url- if set then add_remote?(remote_name, remote_url) done
    #   :ret_diffs - if present then this method will update it with a Repo::Diffs object
    def fast_foward_pull(remote_branch, opts = {})
      remote_name = opts[:remote_name] || default_remote_name
      remote_ref  = "#{remote_name}/#{remote_branch}"

      if remote_url = opts[:remote_url]
        add_remote?(remote_name, remote_url)
      end

      merge_rel = ret_merge_relationship(:remote_branch, remote_ref, fetch_if_needed: true)
      ret =
        case merge_rel
         when :equal then :no_change
         when :branchpoint, :local_ahead then :merge_needed
         when :local_behind then :changed
         else fail Error.new("Unexpected merge relation (#{merge_rel})")
        end

      # computed after a fetch and before a merge
      opts[:ret_diffs] = diff(remote_ref) if opts.has_key?(:ret_diffs)

      if opts[:force]
        checkout(@branch) do
          git_command__hard_reset(remote_ref)
        end
        ret = :changed
      else
        return ret unless ret == :changed
        checkout(@branch) do
          git_command__merge(remote_ref) #TODO: should put in semantic commit message
        end
      end

      ret
    end

    # returns :no_change, :changed, :merge_needed
    def fast_foward_merge_from_branch(branch_to_merge_from)
      merge_rel = ret_merge_relationship(:local_branch, branch_to_merge_from)
      ret =
        case merge_rel
         when :equal then :no_change
         when :branchpoint, :local_ahead then :merge_needed
         when :local_behind then :changed
         else fail Error.new("Unexpected merge relation (#{merge_rel})")
        end
      return ret unless ret == :changed
      checkout(@branch) do
        git_command__merge(branch_to_merge_from) #TODO: should put in semantic commit message
        push_changes
      end
      ret
    end

    def hard_reset_to_branch(branch_to_reset_from)
      checkout(@branch) do
        git_command__hard_reset(branch_to_reset_from)
        push_changes(force: true)
      end
    end

    def initial_sync_with_remote_repo(remote_name, remote_url, remote_branch)
      add_remote?(remote_name, remote_url)

      # create branch with history from just remote and not merge from existing branch
      create_branch_from_from_just_remote(remote_name, remote_branch)

      # push to local
      push_changes
    end

    def create_branch_from_from_just_remote(remote_name, remote_branch)
      # if no branch current_branch will return 'master'
      init_branch = current_branch

      git_command__change_head_symbolic_ref(@branch)

      # when pulling version after base branch is pulled there are untracked changes in newly created empty branch
      # we need to add and commit them and then use pull --force to override them if not the same as remote files
      add_all_files_and_commit(branch: @branch) unless init_branch.eql?('master') 
      force = true
      pull_changes(remote_name, remote_branch, force)
    end
    private :create_branch_from_from_just_remote

    def add_remote?(remote_name, remote_url)
      unless remote_exists?(remote_name)
        add_remote(remote_name, remote_url)
      end
    end

    def add_remote(remote_name, remote_url)
      git_command__remote_add(remote_name, remote_url)
    end

    def add_or_update_remote(remote_name, remote_url)
      # TODO: may be way to do this in one step with rename
      # update": there is:  git remote set-url [--push] <name> <newurl> [<oldurl>]
      if remote_exists?(remote_name)
        remove_remote(remote_name)
      end
      add_remote(remote_name, remote_url)
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
      ret_config_keys.include?("remote.#{remote_name}.url")
    end

    def branch_head_sha
      if commit = @grit_repo.commit(@branch)
        commit.id
      end
    end

    # returns :equal, :local_behind, :local_ahead, or :branchpoint
    # type can be :remote_branch or :local_branch
    def ret_merge_relationship(type, ref, opts = {})
      if (type == :remote_branch && opts[:fetch_if_needed])
        # TODO: this fetches all branches on the remote; see if anyway to just fetch a specfic branch
        # ref will be of form remote_name/branch
        git_command__fetch(ref.split('/').first)
      end

      other_sha = sha_matching_branch_name(type, ref)
      local_sha = sha_matching_branch_name(:local_branch, @branch)
      ret_sha_relationship(local_sha, other_sha)
    end

    # returns :equal, :local_behind, :local_ahead, or :branchpoint
    def ret_sha_relationship(local_sha, other_sha)
      if other_sha == local_sha
        :equal
      else
        # shas can be different but  they can have same content so do a git diff
        unless any_diffs?(local_sha, other_sha)
          return :equal
        end
        # TODO: see if missing or mis-categorizing any condition below
        if git_command__rev_list_contains?(local_sha, other_sha) then :local_ahead
        elsif git_command__rev_list_contains?(other_sha, local_sha) then :local_behind
        else :branchpoint
        end
      end
    end

    def local_remote_relationship(remote_name, remote_url, remote_branch)
      add_remote?(remote_name, remote_url)
      # TODO: dont think this is rescue needed any more because of the c
      # If fails to fetch remote, do initial sync to load remote repo name and try to fetch remote again
      begin
        git_command__fetch(remote_name)
      rescue Exception => e
        initial_sync_with_remote_repo(remote_name, remote_url, remote_branch)
        git_command__fetch(remote_name)
      end

      remote_sha = sha_matching_branch_name(:remote, "#{remote_name}/#{remote_branch}")
      local_sha = sha_matching_branch_name(:local, @branch)

      if remote_sha == local_sha
        'no change'
      else
        # shas can be different but  they can have same content so do a git diff
        unless any_diffs?(local_sha, remote_sha)
          return 'no change'
        end
        # TODO: see if missing or mis-categorizing any condition below
        if git_command__rev_list_contains?(local_sha, remote_sha) then 'local ahead'
        elsif git_command__rev_list_contains?(remote_sha, local_sha) then 'remote ahead'
        else 'merge needed'
        end
      end
    end

    def get_remote_diffs(remote_name, remote_url, remote_branch)
      add_remote?(remote_name, remote_url)
      # TODO: dont think this is rescue needed any more because of the c
      # If fails to fetch remote, do initial sync to load remote repo name and try to fetch remote again
      begin
        git_command__fetch(remote_name)
      rescue Exception => e
        initial_sync_with_remote_repo(remote_name, remote_url, remote_branch)
        git_command__fetch(remote_name)
      end

      remote_sha = sha_matching_branch_name(:remote, "#{remote_name}/#{remote_branch}")
      local_sha = sha_matching_branch_name(:local, @branch)

      get_diffs(remote_sha, local_sha)
    end

    def get_local_branches_diffs(_repo_name, _module_branch, base_branch, workspace_branch)
      base_sha  = sha_matching_branch_name(:remote, "origin/#{base_branch}")
      local_sha = sha_matching_branch_name(:local, workspace_branch)
      get_diffs(base_sha, local_sha)
    end

    def push_changes(opts = {})
      git_command__push(@branch, opts[:remote_name], opts[:remote_branch], opts)
    end

    def pull_changes(remote_name = nil, remote_branch = nil, force = false)
      # note: even though generated git comamdn hash --git-dir set, need to chdir
      Dir.chdir(@path) do
        git_command__pull(@branch, remote_branch || @branch, remote_name, force)
      end
    end

    def rebase_from_remote(remote_name = nil)
       checkout(@branch) do
        git_command__rebase(@branch, remote_name)
      end
    end

    def fetch_all
      git_command__fetch_all
    end

    def push_implementation
      git_command__push(@branch)
    end

    # opts can have keys:
    #   :squash
    #   :strategy
    def merge_from_branch(branch_to_merge_from, opts = {})
      checkout(@branch) do
        git_command__merge(branch_to_merge_from, opts)
      end
    end

    def add_squashed_subtree(prefix, external_repo, external_branch)
      checkout(@branch) do
        git_command__add_squashed_subtree(prefix, external_repo, external_branch)
      end
    end

    def push_squashed_subtree(prefix, external_repo, external_branch)
      checkout(@branch) do
        git_command__push_squashed_subtree(prefix, external_repo, external_branch)
      end
    end

    def push_to_external_repo(external_repo, external_branch)
      checkout(@branch) do
        git_command__push_to_external_repo(external_repo, external_branch)
      end
    end

    def get_branches
      @grit_repo.branches.map(&:name)
    end

    def self.get_branches(repo)     #TODO: deprecate
      path = "#{R8::Config[:repo][:base_directory]}/#{repo}"
      ::Grit::Repo.new(path).branches.map(&:name)
    end

    def ret_config_keys
      ::Grit::Config.new(@grit_repo).keys
    end

    def ret_config_key_value(key)
      ::Grit::Config.new(@grit_repo).fetch(key)
    end

    def set_config_key_value(key, value)
      ::Grit::Config.new(@grit_repo)[key] = value
    end

    private

    attr_reader :grit_repo

    def current_branch
      @grit_repo.head && @grit_repo.head.name
    end

    # type is :local/:local_branch or :remote/:remote_branch
    def sha_matching_branch_name(type, branch_name)
      ref_matching_branch_name(type, branch_name).commit.id
    end

    def ref_matching_branch_name(type, branch_name)
      ref_matching_branch_name?(type, branch_name) ||
        fail(Error.new("Cannot find #{type} branch (#{branch_name})"))
    end

    def ref_matching_branch_name?(type, branch_name)
      refs =
        case type
          when :local, :local_branch then @grit_repo.heads
          when :remote, :remote_branch then @grit_repo.remotes
          else fail Error.new("Illegal branch type (#{type})")
        end
      refs.find { |r| r.name == branch_name }
    end

    MutexesForRepos = {}

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
        end
      end
      ret
    end

    def git_command__empty_commit
      commit('initial empty commit', '--allow-empty')
    end

    def commit(message, *array_opts)
      Dir.chdir(@path) do
        set_author?
        git_command.commit(cmd_opts, '-m', message, *array_opts)
      end
    end

    def default_remote_name
      'origin'
    end

    # sets author if not set already for repo
    def set_author?(name = nil, email = nil)
      return if @author_set
      name ||= default_author_name
      email ||= default_author_email
      set_config_key_value('user.name', name)
      set_config_key_value('user.email', email)
    end

    def default_author_name
      @default_author_name ||= Common::Aux.running_process_user
    end

    def default_author_email
      "#{default_author_name}@reactor8.com"
    end

    def branch_exists?(branch_name)
      ref_matching_branch_name?(:local, branch_name) ? true : nil
    end

    def remote_branch_exists?(branch_name, remote_name = nil)
      remote_name ||= default_remote_name
      qualified_branch_name = "#{remote_name}/#{branch_name}"
      ref_matching_branch_name?(:remote, qualified_branch_name) ? true : nil
    end

    def git_command
      # TODO: not sure why this does not work:
      # GitCommand.new(@grit_repo ? @grit_repo.git : ::Grit::Git.new(""))
      # only thing losing with below is visbility into failure on clone commands (where @grit_repo.nil? is true)
      @grit_repo ? GitCommand.new(@grit_repo.git) : ::Grit::Git.new('')
    end

    def recursive_create_dir?(path)
      if path =~ Regexp.new('(^.+)/[^/]+$')
        dir = Regexp.last_match(1)
        FileUtils.mkdir_p(dir)
      end
    end

    def full_path(relative_path)
      "#{@path}/#{relative_path}"
    end
  end


end; end
