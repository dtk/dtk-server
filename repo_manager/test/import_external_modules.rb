#!/usr/bin/env ruby
require File.expand_path('common', File.dirname(__FILE__))

options = Hash.new
OptionParser.new do|opts|
   opts.banner = "Usage: import_external_modules.rb MODULE_NAMES]"
end.parse!

module_names = ARGV[0].split(",")

module R8::RepoManager
  SourceBaseDir = "#{Config[:git_user_home]}/core-cookbooks/puppet"
  RepoPrefix = "joe-puppet-"
  WorkspaceBranch = "project-private-joe-v1"
  class ImportModules
    def self.add_modules_from_external_repo_dir(*module_names)
      repo_user_acls = [{:access_rights => "RW+", :repo_username => Config[:admin_user]}]
      module_names.each do |module_name|
        external_dir = "#{SourceBaseDir}/#{module_name}"
        repo_name = "#{RepoPrefix}#{module_name}"
        add_repo_from_external_dir(repo_name,repo_user_acls,external_dir)
      end
    end

   private
    def self.add_repo_from_external_dir(repo_name,repo_user_acls,external_dir)
      repo_created = Admin.create_repo(repo_name,repo_user_acls,:noop_if_exists => true)
      unless repo_created
        Log.info("repo (#{repo_name}) created already")
      end
      
      repo = Repo.new(repo_name)
      Dir.chdir(external_dir) do
        file_paths = Dir["**/*"].reject{|path|File.directory?(path)}
        repo.commit_context("adding files for #{repo_name}") do
          file_paths.each do |file_path|
            content = File.open(file_path){|f|f.read}
            repo.add_or_replace_file(file_path,content)
          end
        end
      end
      repo.create_branch(WorkspaceBranch)
    end
  end
end

R8::RepoManager::ImportModules.add_modules_from_external_repo_dir(*module_names)
