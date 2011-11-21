module XYZ
  class ManageGitServerGitolite < ManageGitServer
    class << self
      def test_pp_config()
#        ar = admin_repo()
#        content = ar.get_file_content(:path => "conf/gitolite.conf")
#        pp content
        users = %w{root remote-server r8server r8client} 
        repo_user_acls = users.map{|u|{:access_rights => "RW+", :user_name => u}}
        repo_obj = {
          :repo_name => "foo",
          :repo_user_acls => repo_user_acls
        }

        pp config_file_content(repo_obj)
      end

      def create_empty_repo(repo_obj)
        raise Error.new("creating repo that exists already") if repos_having_config_files().include(repo_obj[:repo_name]) 
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

      def repo_config_directory()
        "#{admin_directory}conf/repo-configs"
      end
      
      def repo_config_files()
        Dir.chdir(repo_config_directory){Dir["*.conf"]}
      end
      def repos_having_config_files()
        repo_config_files().map{|fn|fn.gsub(/\.conf/,"")}
      end

      def config_file_content(repo_obj)
        repo_name = repo_obj[:repo_name]
        #group users by user rights
        users_rights = Hash.new
        repo_obj[:repo_user_acls].each do |acl|
          (users_rights[acl[:access_rights]] ||= Array.new) << acl[:user_name]
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
