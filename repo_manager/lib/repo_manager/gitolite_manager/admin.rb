require 'erubis'
require 'fileutils'
module R8::RepoManager; class GitoliteManager
  class Admin < self
    class << self
      def create_repo(repo_name,repo_user_acls,opts={})
        ret = repo_name
        repo_config_file = repo_config_file_relative_path(repo_name)
        if repo_config_files().include?(repo_config_file)
          if opts[:noop_if_exists]
            return nil
          elsif opts[:delete_if_exists]
            delete_server_repo(repo_name)
          else
            raise Error.new("trying to create a repo (#{repo_name}) that exists already on gitolite server") 
          end
        end

        content = config_file_content(repo_name,repo_user_acls)
        add_file(repo_config_file,content)
        unless opts[:add_file_only]
          commit("adding repo #{repo_name}")
          push()
        end
        ret
      end

      #creates new user and new repo; error if either exists already
      def create_repo_and_user(repo_name,username,rsa_pub_key,access_rights)
        ret = repo_name

        repo_user_acls = [{:access_rights => access_rights,:repo_username => username}]
        add_user(username,rsa_pub_key, :add_file_only => true)
        create_repo(repo_name,repo_user_acls,:add_file_only => true)

        commit_msg = "creating user (#{username}) and repo (#{repo_name})" 
        commit(commit_msg)
        push()
        ret
      end

      def delete_repo(repo_name)
        ret = repo_name
        #delete the reference to the repo 
        repo_config_file = repo_config_file_relative_path(repo_name)
        delete_file_and_push(repo_config_file)
        #delete the actual repo
        FileUtils.rm_rf bare_repo_dir(repo_name)
        ret
      end

      def add_user(username,rsa_pub_key,opts={})
        ret = username
        key_path = repo_user_public_key_relative_path(username)
        if repo_users_public_keys().include?(key_path)
          if opts[:noop_if_exists]
            return nil
          elsif opts[:delete_if_exists]
            delete_user(username)
          else
            raise Error.new("trying to create a user (#{username}) that exists already on gitolite server") 
          end
        end

        add_file(key_path,rsa_pub_key)
        unless opts[:add_file_only]
          commit("adding rsa pub key for #{username}")
          push()
        end
        ret
      end

      def delete_user(username)
        ret = username
        key_path = repo_user_public_key_relative_path(username)
        delete_file_and_push(key_path)
        ret
      end

     private
      def admin_directory()
        Config[:admin_repo_dir]
      end
      def admin_repo()
        @admin_repo ||= GitRepo::FileAccess.new(admin_directory())
      end

      def repo_config_relative_path()
        "conf/repo-configs"
      end

      def repo_user_public_key_dir_relative_path()
        "keydir"
      end


      def add_file(file,content)
        admin_repo.add_file(file,content)
      end

      def commit(commit_msg)
        admin_repo.commit(commit_msg)
      end

      def push()
        admin_repo.push()
      end

      def add_file_and_push(file,content,commit_msg=nil)
        admin_repo.add_file(file,content)
        admin_repo.commit(commit_msg||"adding #{file}")
        admin_repo.push()
      end

      def delete_file_and_push(file,commit_msg=nil)
        admin_repo.remove_file(file)
        commit(commit_msg||"deleting #{file}")
        push()
      end


      def repo_users_public_keys()
        base_path = repo_user_public_key_dir_relative_path()
        ret_files_under_path(base_path)
      end

      def repo_config_files()
        base_path = repo_config_relative_path
        ret_files_under_path(base_path)
      end

      def ret_files_under_path(base_path)
        paths = admin_repo.ls_r(base_path.split("/").size+1, :files_only => true)
        match_regexp = Regexp.new("^#{base_path}")
        paths.select{|p| p =~ match_regexp}
      end

      def repo_user_public_key_relative_path(username)
        "#{repo_user_public_key_dir_relative_path}/#{username}.pub"
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
end;end

