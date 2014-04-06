module DTK
  class Repo
    module ConnectionToRemoteClassMixin

      def remote_ref(remote_repo_base,remote_repo_namespace)
        "#{remote_repo_base}--#{remote_repo_namespace}"
      end
    end

    module ConnectionToRemoteMixin
      def link_to_remote(local,remote)
        RepoManager.link_to_remote_repo(get_field?(:repo_name),local.branch_name,remote.remote_ref(),remote.repo_url())
      end

      def push_to_remote(local,remote)
        RepoManager.push_to_remote_repo(get_field?(:repo_name),local.branch_name,remote.remote_ref,remote.branch_name)
      end
      
      def linked_remote?()
        Log.error("deprecate linked_remote?()")
        get_field?(:remote_repo_name)
      end

      def ret_remote_merge_relationship(remote_ref,local_branch,version,opts={})
        remote_ref ||= get_remote_ref()
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.ret_remote_merge_relationship(get_field?(:repo_name),local_branch,remote_ref,opts.merge(:remote_branch => remote_branch))
      end

      def ret_local_remote_diff(module_branch,remote_repo,opts={})
        version = opts[:version]
        remote_url = remote_repo.url_ssh_access()
        remote_ref = remote_repo.get_remote_ref()
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.get_loaded_and_remote_diffs(remote_ref, get_field?(:repo_name), module_branch, remote_url, remote_branch)
      end
      
      def remote_exists?(remote_repo_name)
        remote_url = repo_url_ssh_access(remote_repo_name)
        RepoManager.git_remote_exists?(remote_url)
      end

      def unlink_remote(remote_ref)
        remote_ref ||= get_remote_ref()
        RepoManager.unlink_remote(get_field?(:repo_name),remote_ref)
        
        update(:remote_repo_name => nil, :remote_repo_namespace => nil)
      end

      def repo_url_ssh_access(remote_repo_name=nil)
        if remote_repo_name.nil?
          Log.error("#TODO: ModuleBranch::Location: deprecating: repo_url_ssh_access")
        end
        remote_repo_name ||= get_field?(:remote_repo_name)
        RepoManagerClient.repo_url_ssh_access(remote_repo_name)
      end

      def get_remote_ref(opts={})
        Log.error_pp(["#TODO: ModuleBranch::Location: deprecating: get_remote_ref",caller[0..3]])
        remote_repo_base = opts[:remote_repo_base]||Remote.default_remote_repo_base()
        if remote_repo_namespace = get_field?(:remote_repo_namespace)
          Repo.remote_ref(remote_repo_base,remote_repo_namespace)
        else
          Log.error("Not expecting :remote_repo_namespace to be nil")
          remote_repo_base
        end
      end
    end
  end
end

