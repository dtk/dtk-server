module Ramaze::Helper
  module RemotesHelper

    def info_git_remote(module_obj)
      info = module_obj.get_linked_remote_repos.collect do |a|
        provider_name = a.git_provider_name
        unless ::DTK::RepoRemote::DTKN_PROVIDER.eql?(provider_name)
          a.merge(:url => a.git_remote_url, :git_provider => provider_name)
        end
      end

      rest_ok_response info.compact
    end

    def add_git_url(repo_remote_mh, repo_id, remote_url)
      remote_name = ::DTK::RepoRemote.git_provider_name(remote_url)
      ::DTK::RepoRemote.create_git_remote(repo_remote_mh, repo_id, remote_name, remote_url)
    end

    def add_git_remote(module_obj)
      remote_name, remote_url = ret_non_null_request_params(:remote_name, :remote_url)
      repo_remote_mh   = module_obj.model_handle(:repo_remote)

      response = ::DTK::RepoRemote.create_git_remote(repo_remote_mh, module_obj.get_workspace_repo.id, remote_name, remote_url)

      rest_ok_response response
    end

    def remove_git_remote(module_obj)
      remote_name      = ret_non_null_request_params(:remote_name)
      repo_remote_mh   = module_obj.model_handle(:repo_remote)

      ::DTK::RepoRemote.delete_git_remote(repo_remote_mh, remote_name, module_obj.get_workspace_repo.id)

      rest_ok_response
    end

  end
end