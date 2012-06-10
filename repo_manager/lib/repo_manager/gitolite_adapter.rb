require 'erubis'
require 'fileutils'
module R8::RepoManager; class GitoliteAdapter
  class Admin 
    class << self
      def create_repo(repo_name,repo_user_acls,opts={})
        ret = repo_name
        repo_config_file_path = repo_config_file_relative_path(repo_name)
        if repo_config_file_paths().include?(repo_config_file_path)
          if opts[:noop_if_exists]
            return nil
          elsif opts[:delete_if_exists]
            delete_server_repo(repo_name)
          else
            raise Error.new("trying to create a repo (#{repo_name}) that exists already on gitolite server") 
          end
        end

        content = generate_config_file_content(repo_name,repo_user_acls)
        add_file(repo_config_file_path,content)
        unless opts[:add_file_only]
          commit("adding repo (#{repo_name})")
          push()
        end
        ret
      end

      def add_user_to_repo(username,repo_name,access_rights)
        ret = repo_name
        repo_user_acls = get_existing_repo_user_acls(repo_name)
        if match = repo_user_acls.find{|r|r[:repo_username] == username}
          raise Error.new("User (#{username}) already has access rights to repo (#{repo_name}): #{match[:access_rights]}")
        end
        
        augmented_repo_user_acls = repo_user_acls + [{:repo_username => username, :access_rights => access_rights}]
        content = generate_config_file_content(repo_name,augmented_repo_user_acls)
        repo_config_file_path = repo_config_file_relative_path(repo_name)

        add_file(repo_config_file_path,content)
        commit("updating repo (#{repo_name}) to give access to user (#{username})")
        push()
        ret
      end

      def delete_repo(repo_name)
        ret = repo_name
        #delete the reference to the repo 
        repo_config_file_path = repo_config_file_relative_path(repo_name)
        delete_file_and_push(repo_config_file_path)
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
        #TODO: may want to remove all refs to user in .conf files
        ret = username
        key_path = repo_user_public_key_relative_path(username)
        delete_file_and_push(key_path)
        ret
      end

     private
      Config = ::R8::RepoManager::Config
      def bare_repo_dir(repo_name)
        ::R8::RepoManager::bare_repo_dir(repo_name)
      end

      def admin_directory()
        Config[:admin_repo_dir]
      end
      def admin_repo()
        @admin_repo ||= GritAdapter::FileAccess.new(admin_directory())
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

      def repo_config_file_paths()
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

      def get_existing_repo_user_acls(repo_name)
        ret = Array.new
        raw_content = admin_repo.file_content(repo_config_file_relative_path(repo_name))
        unless raw_content
          raise Error.new("Repo (#{repo_name}) does not exist")
        end
        #expections is that has form given by ConfigFileTemplate)
        raw_content.each do |l|
          l.chomp!()
          if l =~ /^[ ]*repo[ ]+([^ ]+)/
            unless $1 == repo_name
              raise Error.new("Parsing error: expected repo to be (${repo_name} in (#{l})")
            end
          elsif l =~ /[ ]*([^ ]+)[ ]*=[ ]*(.+)$/
            access_rights = $1
            users = $2
            users.scan(/[^ ]+/)  do |user|
              ret << {:access_rights => access_rights, :repo_username => user}
            end
          else
            raise Error.new("Parsing error: (#{l})")
          end
        end
        ret
      end

      def generate_config_file_content(repo_name,repo_user_acls)
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
