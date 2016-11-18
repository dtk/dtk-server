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
module DTK
  class RepoManager
    require_relative('repo_manager/constant')
    require_relative('repo_manager/add_remote_files_info')
    require_relative('repo_manager/transaction')

    class << self
      # admin and repo methods that just pass to lower level object or class
      RepoMethods = [:move_file, :file_changed_since_specified_sha, :add_all_files_and_commit, :add_remote_files, :push_changes, :push_implementation, :add_branch, :add_branch?, :add_branch_and_push?, :merge_from_branch, :delete_local_and_remote_branch, :add_remote, :pull_changes, :diff, :ls_r, :fast_foward_merge_from_branch, :hard_reset_to_branch, :fetch_all, :rebase_from_remote, :diff, :fast_foward_pull, :delete_file?, :delete_directory?, :branch_head_sha, :move_content, :file_exists?, :add_squashed_subtree, :push_squashed_subtree]
      AdminMethods = [:list_repos, :repo_url, :repo_server_dns, :repo_server_ssh_rsa_fingerprint, :repo_name, :set_user_rights_in_repos, :remove_user_rights_in_repos, :add_user, :delete_user, :get_keydir]

      def method_missing(name, *args, &block)
        if RepoMethods.include?(name)
          context = args.pop
          repo_manager_adapter = get_adapter_repo(context)
          repo_manager_adapter.send(name, *args, &block)
        elsif klass = class_if_admin_method?(name)
          klass.send(name, *args, &block)
        else
          super
        end
      end

      def respond_to?(name)
        !!(defined_method?(name) || super)
      end

      def get_file_content(file_path_hash_or_string, context, opts = {})
        file_path_hash = file_path_hash_form(file_path_hash_or_string)
        get_adapter_repo(context).get_file_content(file_path_hash, opts)
      end

      def files(context)
        get_adapter_repo(context).ls_r
      end

      # signature is
      # def add_file(file_path_hash_or_string, content, commit_msg=nil, context)
      # returns a Boolean: true if any change made
      def add_file(*args)
        context = args.pop
        file_path_hash_or_string, content, commit_msg = args
        file_path_hash = file_path_hash_form(file_path_hash_or_string)
        get_adapter_repo(context).add_file(file_path_hash, content, commit_msg)
      end
      
      # opts can have keys:
      #   :commit_msg
      #   :no_commit
      def add_files(context, file_path__content_array, opts = {})
        get_adapter_repo(context).add_files(file_path__content_array, no_commit: opts[:no_commit], commit_msg: opts[:commit_msg])
      end

      def update_file_content(file_path_hash_or_string, content, context)
        file_path_hash = file_path_hash_form(file_path_hash_or_string)
        get_adapter_repo(context).update_file_content(file_path_hash, content)
      end

      private

      def file_path_hash_form(hash_or_string)
        hash_or_string.is_a?(String) ? { path: hash_or_string } : hash_or_string
      end

      def defined_method?(name)
        RepoMethods.include?(name) || !!class_if_admin_method?(name)
      end

      def class_if_admin_method?(name)
        load_and_return_adapter_class if AdminMethods.include?(name)
      end
    end

    #### for interacting with particular repo
    def self.delete_all_branches(repo_mh)
      repo_names = get_all_repo_names(repo_mh)
      delete_branches(*repo_names)
    end
    def self.delete_branches(*repo_names)
      klass = load_and_return_adapter_class
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
          get_adapter_repo(context).delete_loacl_and_remote_branch
        end
      end
    end

    ### for dealing with actual repos
    class << self
      def initial_sync_with_remote_repo(branch, repo_name, remote_name, remote_url, remote_branch)
        adapter_repo = get_adapter_repo(context(repo_name, branch))
        adapter_repo.initial_sync_with_remote_repo(remote_name, remote_url, remote_branch)
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
        adapter_repo.local_remote_relationship(remote_r, remote_u, remote_b)
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
        klass = load_and_return_adapter_class
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

    # opts can have keys:
    #  :delete_if_exists - Boolean (default: false)
    #  :push_created_branch  - Boolean (default: false)
    #  :donot_create_master_branch - Boolean (default: false)
    #  :create_branch  - branch to create (f non nil)
    #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
    def self.create_workspace_repo(repo_obj, repo_user_acls, opts)
      klass = load_and_return_adapter_class
      # create repo on repo server
      klass.create_server_repo(repo_obj, repo_user_acls, opts)
      if R8::Config[:repo][:workspace][:use_local_clones]
        klass.create_repo_clone(repo_obj, opts)
      elsif R8::Config[:repo][:workspace][:update_bare_repo]
        fail Error.new('Have not implemented yet: R8::Config[:repo][:workspace][:update_bare_repo]')
      else
        fail Error.new('Should not reach here!')
      end
    end

    def self.delete_all_repos
      klass = load_and_return_adapter_class
      # delete all repos on repo server
      klass.delete_all_server_repos
      delete_all_local_repos
    end

    def self.delete_repo(repo)
      klass = load_and_return_adapter_class
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
      fail Error.new('cannot find branch in context') unless branch
      (CachedRepoObjects[repo_dir] ||= {})[branch] ||= load_and_create(repo_dir, branch)
    end

    def self.repo_full_path_and_branch(context)
      repo_rel_path, branch = ret_repo_dir_and_branch(context)
      adapter_class = load_and_return_adapter_class
      [adapter_class.repo_full_path(repo_rel_path), branch]
    end

    private

    CachedRepoObjects = {}
    def self.ret_repo_dir_and_branch(context)
      repo_dir = branch = nil

      if context.is_a?(ModuleBranch)
        repo_dir, branch = context.repo_and_branch
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
      fail Error.new('No repo adapter specified') unless adapter_name
      @cached_adapter_class = DynamicLoader.load_and_return_adapter_class('repo_manager', adapter_name, subclass_adapter_name: true)
    end

    def self.load_and_create(repo_dir, branch)
      klass = load_and_return_adapter_class
      klass.create(repo_dir, branch)
    end

    def self.get_all_repo_names(model_handle)
      Repo.get_all_repo_names(model_handle)
    end

  end
end
