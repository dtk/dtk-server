module XYZ
  module RepoGitManageClassMixin
    def repo_name(username,config_agent_type,module_name)
      git_server_class().repo_name(username,config_agent_type,module_name)
    end

    def create_server_repo(repo_obj,repo_user_acls,opts={})
      git_server_class().create_server_repo(repo_obj,repo_user_acls,opts)
    end

    def delete_all_server_repos()
      git_server_class().delete_all_server_repos()
    end

   private
    def git_server_class()
      return @git_server_class if @git_server_class
      adapter_name = ((R8::Config[:repo]||{})[:git]||{})[:server_type]
      raise Error.new("No repo git server adapter specified") unless adapter_name
      @git_server_class = DynamicLoader.load_and_return_adapter_class("manage_git_server",adapter_name)
      @git_server_class.set_git_class(self)
    end
  end
  class ManageGitServer
  end
end
