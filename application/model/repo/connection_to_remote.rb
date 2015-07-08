module DTK
  class Repo
    module ConnectionToRemoteClassMixin
      def remote_ref(remote_repo_base,remote_repo_namespace)
        Log.info_pp(["#TODO: ModuleBranch::Location: deprecate: remote_ref",caller[0..4]])
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

      def ret_local_remote_diff(module_branch,remote)
        remote_url = remote.repo_url()
        remote_ref = remote.remote_ref()
        remote_branch = remote.branch_name()
        RepoManager.get_loaded_and_remote_diffs(remote_ref, get_field?(:repo_name), module_branch, remote_url, remote_branch)
      end

      def get_remote_diffs(module_branch,remote)
        remote_url = remote.repo_url()
        remote_ref = remote.remote_ref()
        remote_branch = remote.branch_name()
        RepoManager.get_remote_diffs(remote_ref, get_field?(:repo_name), module_branch, remote_url, remote_branch)
      end

      def get_local_branches_diffs(module_branch,base_branch, workspace_branch)
        RepoManager.get_local_branches_diffs(get_field?(:repo_name), module_branch, base_branch, workspace_branch)
      end

      def hard_reset_branch_to_sha(module_branch, sha)
        RepoManager.hard_reset_branch_to_sha(get_field?(:repo_name), module_branch, sha)
      end
    end
  end
end
