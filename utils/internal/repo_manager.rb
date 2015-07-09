require 'fileutils'

module DTK
  class RepoManager
    class << self
      # admin and repo methods that just pass to lower level object or class
      RepoMethods = [:add_all_files, :push_changes, :push_implementation, :add_branch, :add_branch?, :add_branch_and_push?, :merge_from_branch, :delete_branch, :add_remote, :pull_changes, :diff, :ls_r, :fast_foward_merge_from_branch, :hard_reset_to_branch, :fetch_all, :rebase_from_remote, :diff, :fast_foward_pull, :delete_file?, :delete_directory?, :branch_head_sha, :move_content]
      AdminMethods = [:list_repos, :repo_url, :repo_server_dns, :repo_server_ssh_rsa_fingerprint, :repo_name, :set_user_rights_in_repos, :remove_user_rights_in_repos, :add_user, :delete_user, :get_keydir]

      def method_missing(name, *args, &block)
        if RepoMethods.include?(name)
          context = args.pop
          return get_adapter_repo(context).send(name, *args, &block)
        end
        if klass = class_if_admin_method?(name)
          return klass.send(name, *args, &block)
        end
        super
      end

      def respond_to?(name)
        !!(defined_method?(name) || super)
      end

      def get_file_content(file_obj_or_path, context, opts = {})
        file_obj_or_path = { path: file_obj_or_path } if file_obj_or_path.is_a?(String)
        get_adapter_repo(context).get_file_content(file_obj_or_path, opts)
      end

      # signature is effectively def add_file(file_obj_or_path,content,commit_msg=nil,context)
      def add_file(*args)
        context = args.pop
        file_obj_or_path, content, commit_msg = args
        file_obj_or_path = { path: file_obj_or_path } if file_obj_or_path.is_a?(String)
        get_adapter_repo(context).add_file(file_obj_or_path, content, commit_msg)
      end

      def update_file_content(file_obj_or_path, content, context)
        file_obj_or_path = { path: file_obj_or_path } if file_obj_or_path.is_a?(String)
        get_adapter_repo(context).update_file_content(file_obj_or_path, content)
      end

      private

      def defined_method?(name)
        RepoMethods.include?(name) || !!class_if_admin_method?(name)
      end

      def class_if_admin_method?(name)
        load_and_return_adapter_class() if AdminMethods.include?(name)
      end
    end

    #### for interacting with particular repo
    def self.delete_all_branches(repo_mh)
      repo_names = get_all_repo_names(repo_mh)
      delete_branches(*repo_names)
    end
    def self.delete_branches(*repo_names)
      klass = load_and_return_adapter_class()
      repo_names.each do |repo_name|
        # TODO: change so this from Repo if want to put in hooks for per branch auth
        klass.get_branches(repo_name).each do |branch|
          next if branch == 'master'
          pp "deleting branch (#{branch}) in repo (#{repo_name})"
          context = {
            implementation: {
              repo: repo_name,
              branch: branch
            }
          }
          get_adapter_repo(context).delete_branch()
        end
      end
    end

    ### for dealing with actual repos
    class << self
      def initial_sync_with_remote_repo(branch, repo_name, remote_name, remote_url, remote_branch, opts = {})
        adapter_repo = get_adapter_repo(context(repo_name, branch))
        adapter_repo.initial_sync_with_remote_repo(remote_name, remote_url, remote_branch, opts)
      end

     def pull_from_remote_repo(branch, repo_name, remote_name, remote_url, remote_branch, opts = {})
        adapter_repo = get_adapter_repo(context(repo_name, branch))
        adapter_repo.pull_from_remote_repo(remote_name, remote_url, remote_branch, opts)
      end

      # returns :equal, :local_behind, :local_ahead, or :branchpoint
      # branch object can be for either sha; result does not matter based on this
      def ret_sha_relationship(local_sha, other_sha, branch_obj)
        adapter_repo = get_adapter_repo(branch_obj)
        adapter_repo.ret_sha_relationship(local_sha, other_sha)
      end

      # remote_r - remote_ref
      # remote_u - remote_url
      # remote_b - remote_branch
      def get_loaded_and_remote_diffs(remote_r, repo_name, module_branch, remote_u, remote_b)
        adapter_repo = get_adapter_repo(context(repo_name, module_branch))
        adapter_repo.is_different_than_remote?(remote_r, remote_u, remote_b)
      end

      def get_remote_diffs(remote_r, repo_name, module_branch, remote_u, remote_b)
        adapter_repo = get_adapter_repo(context(repo_name, module_branch))
        adapter_repo.get_remote_diffs(remote_r, remote_u, remote_b)
      end

      def get_local_branches_diffs(repo_name, module_branch, base_branch, workspace_branch)
        adapter_repo = get_adapter_repo(context(repo_name, module_branch))
        adapter_repo.get_local_branches_diffs(repo_name, module_branch, base_branch, workspace_branch)
      end

      def hard_reset_branch_to_sha(repo_name, module_branch, sha)
        adapter_repo = get_adapter_repo(context(repo_name, module_branch))
        # hard reset to specific sha in the branch
        adapter_repo.hard_reset_to_branch(sha)
      end

      def push_to_remote_repo(repo_name, branch, remote_name, remote_branch = nil)
        adapter_repo = get_adapter_repo(context(repo_name, branch))
        adapter_repo.push_changes(remote_name: remote_name, remote_branch: remote_branch)
        repo_name
      end

      def git_remote_exists?(remote_url)
        klass = load_and_return_adapter_class()
        klass.git_remote_exists?(remote_url)
      end

      def link_to_remote_repo(repo_name, branch, remote_name, remote_url)
        adapter_repo = get_adapter_repo(context(repo_name, branch))
        adapter_repo.add_or_update_remote(remote_name, remote_url)
        repo_name
      end

      def unlink_remote(repo_name, remote_name)
        adapter_repo = get_adapter_repo(context(repo_name, 'master'))
        adapter_repo.remove_remote?(remote_name)
      end

      private

      def context(repo_name, branch)
        if branch.is_a?(ModuleBranch)
          branch
        else
          unless repo_name.is_a?(String)
            Log.error("unexpected type for repo_name: #{repo_name.inspect}")
          end
          unless branch.is_a?(String)
            Log.error("unexpected type for branch: #{branch.inspect}")
          end
          { implementation: { repo: repo_name, branch: branch } }
        end
      end
    end

    ###### for repo admin functions, such as creating and deleting repositories

    def self.create_workspace_repo(repo_obj, repo_user_acls, opts)
      klass = load_and_return_adapter_class()
      # create repo on repo server
      klass.create_server_repo(repo_obj, repo_user_acls, opts)
      if R8::Config[:repo][:workspace][:use_local_clones]
        klass.create_repo_clone(repo_obj, opts)
      elsif R8::Config[:repo][:workspace][:update_bare_repo]
        raise Error.new('Have not implemented yet: R8::Config[:repo][:workspace][:update_bare_repo]')
      else
        raise Error.new('Should not reach here!')
      end
    end

    def self.delete_all_repos
      klass = load_and_return_adapter_class()
      # delete all repos on repo server
      klass.delete_all_server_repos()
      delete_all_local_repos()
    end

    def self.delete_repo(repo)
      klass = load_and_return_adapter_class()
      repo.update_object!(:repo_name, :local_dir)
      klass.delete_server_repo(repo[:repo_name])
      delete_local_repo(repo[:local_dir])
    end

    class << self
      def delete_local_repo(repo_local_dir)
        FileUtils.rm_rf repo_local_dir if File.directory?(repo_local_dir)
      end

      def delete_all_local_repos
        repo_base_dir = R8::Config[:repo][:base_directory]
        if File.directory?(repo_base_dir)
          Dir.chdir(R8::Config[:repo][:base_directory]) do
            Dir['*'].each { |local_repo_dir| FileUtils.rm_rf local_repo_dir }
          end
        end
      end
      private :delete_local_repo, :delete_all_local_repos
    end

    ##########
    def self.get_adapter_repo(context)
      repo_dir, branch = ret_repo_dir_and_branch(context)
      raise Error.new('cannot find branch in context') unless branch
      CachedRepoObjects[repo_dir] ||= {}
      CachedRepoObjects[repo_dir][branch] ||= load_and_create(repo_dir, branch)
    end

    def self.repo_full_path_and_branch(context)
      repo_rel_path, branch = ret_repo_dir_and_branch(context)
      adapter_class = load_and_return_adapter_class()
      [adapter_class.repo_full_path(repo_rel_path), branch]
    end

    private

    CachedRepoObjects = {}
    def self.ret_repo_dir_and_branch(context)
      repo_dir = branch = nil

      if context.is_a?(ModuleBranch)
        repo_dir, branch = context.repo_and_branch()
      elsif context.is_a?(Repo)
        context.update_object!(:repo_name)
        repo_dir = context[:repo_name]
        branch = 'master'
      elsif context.is_a?(Implementation)
        context.update_object!(:repo, :branch)
        repo_dir = context[:repo]
        branch = context[:branch]
      elsif context.is_a?(Hash) && context[:repo_dir] && context[:branch]
        repo_dir = context[:repo_dir]
        branch = context[:branch]
      else
        # TODO: deprecate after replace use of this pattern
        # assume that it has hash with :implementation key
        # TODO: do we still need __top
        repo_dir = (context[:implementation] || {})[:repo] || '__top'
        branch = (context[:implementation] || {})[:branch]
      end
      [repo_dir, branch]
    end

    def self.load_and_return_adapter_class
      return @cached_adapter_class if @cached_adapter_class
      adapter_name = (R8::Config[:repo] || {})[:type]
      raise Error.new('No repo adapter specified') unless adapter_name
      @cached_adapter_class = DynamicLoader.load_and_return_adapter_class('repo_manager', adapter_name)
    end

    def self.load_and_create(repo_dir, branch)
      klass = load_and_return_adapter_class()
      klass.create(repo_dir, branch)
    end

    def self.get_all_repo_names(model_handle)
      Repo.get_all_repo_names(model_handle)
    end
  end

  class RemoteRepoManager < RepoManager
    def self.load_and_return_adapter_class
      return @cached_adapter_class if @cached_adapter_class
      adapter_name = 'remote_repo'
      @cached_adapter_class = DynamicLoader.load_and_return_adapter_class('repo_manager', adapter_name)
    end
  end
end
