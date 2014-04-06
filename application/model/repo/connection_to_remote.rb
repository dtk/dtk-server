module DTK
  class Repo
    module ConnectionToRemoteClassMixin
      def remote_ref(remote_repo_base,remote_repo_namespace)
        Log.error("#TODO: ModuleBranch::Location: deprecate: remote_ref")
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

      def unlink_remote(remote)
        RepoManager.unlink_remote(get_field?(:repo_name),remote.remote_ref)
      end

      #TODO: ModuleBranch::Location: switch over to passing in remote
      def ret_local_remote_diff(module_branch,remote_repo,opts={})
        version = opts[:version]
        remote_url = remote_repo.url_ssh_access()
        remote_ref = remote_repo.get_remote_ref()
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.get_loaded_and_remote_diffs(remote_ref, get_field?(:repo_name), module_branch, remote_url, remote_branch)
      end
    end
  end
end

