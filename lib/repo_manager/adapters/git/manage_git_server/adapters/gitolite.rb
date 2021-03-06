#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'erubis'
module DTK
  class RepoManager::Git::ManageGitServer
    class Gitolite < self
      ALLOWED_CHARACTERS = /[a-zA-Z0-9\-_\.]*/
      
      class << self
        def create_server_repo(repo_obj, repo_user_acls, opts = {})
          ret = repo_name = repo_obj[:repo_name]
          
          validate_repo_module_name!(repo_name)
          if repos_having_config_files.include?(repo_name)
            if opts[:delete_if_exists]
              delete_server_repo(repo_name)
            else
              fail Error.new("trying to create a repo (#{repo_name}) that exists already on gitolite server")
            end
          end
          
          config_dir = repo_config_directory
          Dir.mkdir(config_dir) unless File.directory?(config_dir)
          path = repo_config_file_relative_path(repo_name)
          file_asset_hash = { path: path }
          content = generate_config_file_content(repo_name, repo_user_acls)
          admin_repo.add_file(file_asset_hash, content)
          admin_repo.push_changes
          update_bare_repo_config(repo_name)
          ret
        end
        
        def delete_all_server_repos
          admin_repo.pull_changes
          repo_config_files.each do |repo_conf|
            repo_name = repo_conf.gsub(/\.conf/, '')
            delete_server_repo(repo_name, do_not_pull_changes: true, do_not_push_changes: true)
          end
          admin_repo.push_changes
        end
        
        def set_git_class(git_class)
          @git_class = git_class
        end
        
        def delete_server_repo(repo_name, opts = {})
          admin_repo.pull_changes unless opts[:do_not_pull_changes]
          file_path = repo_config_file_relative_path(repo_name)
          file_deleted = admin_repo.delete_file?(file_path)
          admin_repo.push_changes unless opts[:do_not_push_changes] or not file_deleted
          delete_bare_repo?(repo_name)
        end
        
        def delete_bare_repo?(repo_name)
          unless R8::Config[:git_server_on_dtk_server]
            Log.error('Not implemented yet: delete_bare_repo when R8::Config[:git_server_on_dtk_server] is not true')
            return
          end
          begin
            `sudo rm -r -f #{bare_repo_dir(repo_name)}`
          rescue => e
            Log.error(e.inspect)
          end
        end
        
        def add_user(username, rsa_pub_key, opts = {})
          ret = username
          key_path = repo_user_public_key_relative_path(username)
          if repo_users_public_keys.include?(key_path)
            if opts[:noop_if_exists]
              return nil
            elsif opts[:delete_if_exists]
              delete_user(username)
            else
              fail Error.new("trying to create a user (#{username}) that exists already on gitolite server")
            end
          end
          
          commit_msg = "adding rsa pub key for #{username}"
          admin_repo.add_file({ path: key_path }, rsa_pub_key, commit_msg)
          admin_repo.push_changes
          ret
        end
        
        def delete_user(username)
          # TODO: may want to remove all refs to user in .conf files
          ret = username
          key_path = repo_user_public_key_relative_path(username)
          file_deleted = admin_repo.delete_file?(key_path)
          if file_deleted
            admin_repo.push_changes
          end
          ret
        end
        
        def remove_user_rights_in_repos(username, repo_names)
          set_user_rights_in_repos(username, repo_names, '')
        end
        
        # access_rights="" means remove access rights
        def set_user_rights_in_repos(username, repo_names, access_rights = 'R')
          repo_names = [repo_names] unless repo_names.is_a?(Array)
          updated_repos = []
          
          repo_names.each do |repo_name|
            repo_user_acls = get_existing_repo_user_acls(repo_name)
            match = repo_user_acls.find { |r| r[:repo_username] == username }
            if match
              # no op if username has specified rights
              next if match[:access_rights] == access_rights
              repo_user_acls.reject! { |r| r[:repo_username] == username }
            else
              # no op if username does not appear in repo and access_rights="", meaning remove access rights
              next if access_rights.empty?
            end
            updated_repos << repo_name
            
            augmented_repo_user_acls = repo_user_acls
            unless access_rights.empty?
              augmented_repo_user_acls << { repo_username: username, access_rights: access_rights }
            end

            content = generate_config_file_content(repo_name, augmented_repo_user_acls)
            repo_config_file_path = repo_config_file_relative_path(repo_name)
            commit_msg = "updating repo (#{repo_name}) to give access to user (#{username})"
            admin_repo.add_file({ path: repo_config_file_path }, content, commit_msg)
          end
          admin_repo.push_changes unless updated_repos.empty?
          updated_repos
        end
        
        # get gitolite_admin keydir location
        def get_keydir
          "#{admin_directory}keydir"
        end
        
        private
        
        def admin_directory
          @admin_directory ||= R8::Config[:repo][:git][:gitolite][:admin_directory]
        end

        def admin_repo
          @admin_repo ||= @git_class.create(admin_directory, 'master', absolute_path: true)
        end

        def bare_repo(repo_name)
          @git_class.create(bare_repo_dir(repo_name), 'master', absolute_path: true)
        end

        def bare_repo_dir(repo_name)
          "#{R8::Config[:git_user_home]}/repositories/#{repo_name}.git"
        end
        
        def repo_user_public_key_relative_path(username)
          "#{repo_user_public_key_dir_relative_path}/#{username}.pub"
        end
        
        def repo_user_public_key_dir_relative_path
          'keydir'
        end

        def repo_users_public_keys
          base_path = repo_user_public_key_dir_relative_path
          ret_files_under_path(base_path)
        end

        def ret_files_under_path(base_path)
          paths = admin_repo.ls_r(base_path.split('/').size + 1, files_only: true)
          match_regexp = Regexp.new("^#{base_path}")
          paths.select { |p| p =~ match_regexp }
        end
        
        def repo_config_relative_path
          'conf/repo-configs'
        end
        
        def repo_config_directory
          "#{admin_directory}/#{repo_config_relative_path}"
        end

        def repo_config_files
          return [] unless File.directory?(repo_config_directory)
          Dir.chdir(repo_config_directory) { Dir['*.conf'] }
        end

        def repos_having_config_files
          repo_config_files.map { |fn| fn.gsub(/\.conf/, '') }
        end

        def repo_config_file_relative_path(repo_name)
          "#{repo_config_relative_path}/#{repo_name}.conf"
        end
        
        def get_existing_repo_user_acls(repo_name)
          ret = []
          raw_content = admin_repo.get_file_content(path: repo_config_file_relative_path(repo_name))
          unless raw_content
            fail Error.new("Repo (#{repo_name}) does not exist")
          end
          # expections is that has form given by ConfigFileTemplate)
          raw_content.each_line do |l|
            l.chomp!
            
            if l =~ /^[ ]*include[ ]+.*/
              # we ignore this line
            elsif l =~ /^[ ]*repo[ ]+([^ ]+)/
              unless Regexp.last_match(1) == repo_name
                fail Error.new("Parsing error: expected repo to be (${repo_name} in (#{l})")
              end
            elsif l =~ /[ ]*([^ ]+)[ ]*=[ ]*(.+)$/
              access_rights = Regexp.last_match(1)
              users = Regexp.last_match(2)
              users.scan(/[^ ]+/)  do |user|
                ret << { access_rights: access_rights, repo_username: user }
              end
            elsif l.empty?
              # no op
            else
              fail Error.new("Parsing error: (#{l})")
            end
          end
          ret
        end

        # update_bare_repo_config is to handle error:
        #  remote: error: By default, deleting the current branch is denied, because the next
        #  remote: 'git clone' won't result in any file checked out, causing confusion.
        #  remote: You can set 'receive.denyDeleteCurrent' configuration variable to
        #  remote: 'warn' or 'ignore' in the remote repository to allow deleting the
        def update_bare_repo_config(repo_name)
          bare_repo(repo_name).set_config_key_value('receive.denyDeleteCurrent', 'ignore')
        end

        def validate_repo_module_name!(repo_name)
          unless repo_name.eql? repo_name.match(ALLOWED_CHARACTERS)[0]
            fail Error.new("Illegal characters used in gitolite repo name (#{repo_name}). Letters, numbers and dashes only allowed.")
          end
        end

        def generate_config_file_content(repo_name, repo_user_acls)
          # group users by user rights
          users_rights = {}
          repo_user_acls.each do |acl|
            (users_rights[acl[:access_rights]] ||= []) << acl[:repo_username]
          end
          ConfigFileTemplate.result(repo_name: repo_name, user_rights: users_rights)
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
end
