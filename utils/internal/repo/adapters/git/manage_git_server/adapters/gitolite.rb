module XYZ
  class ManageGitServerGitolite < ManageGitServer
    class << self
      def test_pp_config()
        ar = admin_repo()
        content = ar.get_file_content(:path => "conf/gitolite.conf")
        pp content
      end

      def create_empty_repo(repo_obj)
      end

      def set_git_class(git_class)
        @git_class = git_class
    end
      
   private
      def admin_repo()
        @admin_repo ||= @git_class.create(R8::Config[:repo][:git][:gitolite][:admin_directory],"master",{:absolute_path => true})
      end
    end
  end
end
