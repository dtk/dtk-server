require 'erubis'
module R8::RepoManager
  class GitoliteManager
  end
end
r8_nested_require('gitolite_manager','admin')
r8_nested_require('gitolite_manager','repo')
module R8::RepoManager
  class GitoliteManager
   private
    Config = ::R8::RepoManager::Config

    def self.bare_repo_dir(repo_name)
      "#{Config[:git_user_home]}/repositories/#{repo_name}.git"
    end
    def bare_repo_dir(repo_name)
      self.class.bare_repo_dir(repo_name)
    end
  end
end
