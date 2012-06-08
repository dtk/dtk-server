require File.expand_path('common', File.dirname(__FILE__))

module R8::RepoManager
  SourceBaseDir = "#{Config[:git_user_home]}/core-cookbooks/puppet"
  class ImportModules
    def sdlf.add_modules_from_external_repo_dir(*module_names)
      repo_user_acls = [{:access_rights => "RW+", :repo_username => Config[:admin_user]}]
      module_names.each do |module_name|
        external_dir = "#{SourceBaseDir}/#{module_name}"
        add_module_from_external_repo_dir(module_name,repo_user_acls,external_dir)
      end
    end

   private
    def self.add_repo_from_external_dir(repo_name,repo_user_acls,external_dir)
      repo_created = GitoliteManager::Admin.create_repo(repo_name,repo_user_acls,:noop_if_exists => true)
      unless repo_created
        Log.info("repo (#{repo_name}) created already")
      end
      
      repo = GitoliteManager::Repo.new(repo_name)
      Dir.chdir(external_dir) do
        file_paths = Dir["**/*"].reject{|path|File.directory?(path)}
        repo.commit_context("adding files for #{repo_name}") do
          file_paths.each do |file_path|
            content = File.open(file_path){|f|f.read}
            repo.add_or_replace_file(file_path,content)
          end
        end
      end
    end
  end
end
