module XYZ
  class ManageGitServerGitolite < ManageGitServer
    class << self
      #this gets changed if for example we are able to do per branch read auth
      def repo_name(username,config_agent_type,module_name)
        "#{username}-#{config_agent_type}-#{module_name}"
      end

      def create_server_repo(repo_obj,repo_user_acls,opts={})
        ret = repo_name = repo_obj[:repo_name]
        if repos_having_config_files().include?(repo_name)
          if opts[:delete_if_exists]
            delete_server_repo(repo_name)
          else
            raise Error.new("trying to create a repo (#{repo_name}) that exists already on gitolite server") 
          end
        end

        config_dir = repo_config_directory()
        Dir.mkdir(config_dir) unless File.directory?(config_dir)
        path = repo_config_file_relative_path(repo_name)
        file_asset_hash = {:path => path}
        content = config_file_content(repo_name,repo_user_acls)
        admin_repo.add_file(file_asset_hash,content)
        admin_repo.push_changes()
        ret
      end

      def delete_all_server_repos()
        admin_repo.pull_changes()
        repo_config_files().each do |repo_conf|
          repo_name = repo_conf.gsub(/\.conf/,"")
          delete_server_repo(repo_name,:do_not_pull_changes => true,:do_not_push_changes => true)
        end
        admin_repo.push_changes()
      end

      def set_git_class(git_class)
        @git_class = git_class
      end
      
      def delete_server_repo(repo_name,opts={})
        admin_repo.pull_changes() unless opts[:do_not_pull_changes]
        file_path = repo_config_file_relative_path(repo_name)
        admin_repo.delete_file(file_path)
        admin_repo.push_changes() unless opts[:do_not_push_changes]
      end

     private

      def admin_directory()
        @admin_directory ||= R8::Config[:repo][:git][:gitolite][:admin_directory] 
      end
      def admin_repo()
        @admin_repo ||= @git_class.create(admin_directory(),"master",{:absolute_path => true})
      end

      def repo_config_relative_path()
        "conf/repo-configs"
      end
      def repo_config_directory()
        "#{admin_directory}/#{repo_config_relative_path}"
      end
      def repo_config_files()
        return Array.new unless File.directory?(repo_config_directory)
        Dir.chdir(repo_config_directory){Dir["*.conf"]}
      end
      def repos_having_config_files()
        repo_config_files().map{|fn|fn.gsub(/\.conf/,"")}
      end
      def repo_config_file_relative_path(repo_name)
        "#{repo_config_relative_path}/#{repo_name}.conf"
      end

      def config_file_content(repo_name,repo_user_acls)
        #group users by user rights
        users_rights = Hash.new
        repo_user_acls.each do |acl|
          (users_rights[acl[:access_rights]] ||= Array.new) << acl[:repo_username]
        end
        ConfigFileTemplate.result(:repo_name => repo_name,:user_rights => users_rights)
      end

ConfigFileTemplate = Erubis::Eruby.new <<eos
repo    <%=repo_name %>
<% user_rights.each do |access_rights,users| -%>
        <%=access_rights %>     =  <%=users.join(" ") %>
<% end -%>
eos
    end
  end
end
