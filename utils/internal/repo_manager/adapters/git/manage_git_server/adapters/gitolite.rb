module XYZ
  class ManageGitServerGitolite < ManageGitServer
    class << self
      #this gets changed if for example we are able to do per branch read auth
      def actual_repo_name(repo_obj)
        username = CurrentSession.new.get_user_object()[:username]
        raise Error.new("missing config agent type") unless config_agent_type = repo_obj[:config_agent_type] 
        raise Error.new("missing repo name") unless repo_name = repo_obj[:repo_name]
        "#{username}-#{config_agent_type}-#{repo_name}"
      end

      def create_empty_repo(repo_obj)
        raise Error.new("missing actual_repo_name") unless actual_repo_name = repo_obj[:actual_repo_name]
        raise Error.new("trying to create repo (#{actual_repo_name} that exists already") if repos_having_config_files().include?(actual_repo_name)
        file_asset_hash = {:path => repo_config_file_relative_path(actual_repo_name)}
        content = config_file_content(repo_obj)
        admin_repo.add_file(file_asset_hash,content)
        admin_repo.push_changes()
        actual_repo_name
      end

      def set_git_class(git_class)
        @git_class = git_class
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
        Dir.chdir(repo_config_directory){Dir["*.conf"]}
      end
      def repos_having_config_files()
        repo_config_files().map{|fn|fn.gsub(/\.conf/,"")}
      end
      def repo_config_file_relative_path(actual_repo_name)
        "#{repo_config_relative_path}/#{actual_repo_name}.conf"
      end

      def config_file_content(repo_obj)
        #group users by user rights
        users_rights = Hash.new
        repo_obj[:repo_user_acls].each do |acl|
          (users_rights[acl[:access_rights]] ||= Array.new) << acl[:username]
        end
        ConfigFileTemplate.result(:repo_name => repo_obj[:actual_repo_name],:user_rights => users_rights)
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
