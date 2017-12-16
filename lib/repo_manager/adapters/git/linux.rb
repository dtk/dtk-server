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
require 'fileutils'

module DTK
  class RepoManager::Git
    class Linux < self
      def git_command__add_squashed_subtree(prefix, external_repo, external_branch)
        external_repo_url = self.class.repo_url(external_repo.display_name)
        # subtree add only works if prefix does not exist
        if Dir.exists?("#{@path}/#{prefix}")
          git_command__rm_r(prefix) 
          commit("Removing '#{prefix}' to allow subtree add")
        end
        git_command.subtree(cmd_opts, 'add', '--prefix', prefix, external_repo_url, external_branch, '--squash')
      end
      private

      def git_command__push_squashed_subtree(prefix, external_repo, external_branch)
        external_repo_url = self.class.repo_url(external_repo.display_name)
        git_command.subtree(cmd_opts, 'push', '--prefix', prefix, external_repo_url, external_branch, '--squash')
      end

      def git_command__push_to_external_repo(external_repo, external_branch)
        # TODO: remove this restriction by updating command line in  git_command.push
        unless @branch == external_branch
          fail Error, "The method 'push_to_external_repo' not supported when local branch (#{@branch}) and external_branch (#{external_branch}) are different"
        end
        external_repo_url = self.class.repo_url(external_repo.display_name)
        git_command.push(cmd_opts, external_repo_url, '-f')
      end

      def git_command__clone(remote_repo, local_dir)
        git_command.clone(cmd_opts, remote_repo, local_dir)
      end
      
      def git_command__checkout(branch_name)
        git_command.checkout(cmd_opts, branch_name)
      end
      
      def git_command__add_branch(branch_name)
        git_command.branch(cmd_opts, branch_name)
      end
      
      def git_command__change_head_symbolic_ref(branch_name)
        git_command.symbolic_ref(cmd_opts, 'HEAD', "refs/heads/#{branch_name}")
      end
      
      def git_command__add(file_path)
      # put in -f to avoid error being thrown if try to add an ignored file
        git_command.add(cmd_opts, file_path, '-f')
        # took out because could not pass in time out @grit_repo.add(file_path)
      end
      
      def git_command__rm(file_path)
        # git_command.rm uses form /usr/bin/git --git-dir=.. rm <file>; which does not delete the working directory file, so
        # need to use os comamdn to dleet file and just delete the file from the index
        git_command.rm(cmd_opts, '--cached', file_path)
        FileUtils.rm_f full_path(file_path)
      end
      
      def git_command__rm_r(dir)
        full_path = full_path(dir)
        if File.exists?(full_path)
          git_command.rm(cmd_opts, '-r', '--cached', dir)
          FileUtils.rm_rf full_path
        end
      end
      
      def git_command__mv(source, destination, files, folders)
        FileUtils.mkdir_p(destination)
        
        files.each do |file|
          git_command.mv(cmd_opts, '--force', "#{source}/#{file}", "#{destination}/#{file}")
        end
        
        folders.each do |folder|
          git_command.mv(cmd_opts, '--force', "#{source}/#{folder}", "#{destination}/")
          FileUtils.rmdir("#{source}/#{folder}")
        end
      end
      
      def git_command__mv_file(source_name, destination_name)
        git_command.mv(cmd_opts, '--force', "#{source_name}", "#{destination_name}")
      end
      
      def git_command__remote_add(remote_name, remote_url)
        git_command.remote(cmd_opts, :add, remote_name, remote_url)
      end
      
      def git_command__remote_rm(remote_name)
        git_command.remote(cmd_opts, :rm, remote_name)
      end
      
      def git_command__fetch(remote_name)
        git_command.fetch(cmd_opts, remote_name)
      end
      
      def git_command__fetch_all
        git_command.fetch(cmd_opts, '--all')
      end
      
      # TODO: see what other commands needs mutex and whether mutex across what boundaries
      Git_command__push_mutex = Mutex.new
      # returns sha of remote haed
      def git_command__push(branch_name, remote_name = nil, remote_branch = nil, opts = {})
        ret = nil
        Git_command__push_mutex.synchronize do
          remote_name ||= default_remote_name
          remote_branch ||= branch_name
          args = [cmd_opts, remote_name, "#{branch_name}:refs/heads/#{remote_branch}"]
          args << '-f' if opts[:force]
          git_command.push(*args)
          remote_name = "#{remote_name}/#{remote_branch}"
          ret = sha_matching_branch_name(:remote, remote_name)
        end
        ret
      end
      
      def git_command__rev_list_contains?(container_sha, index_sha)
        rev_list = git_command.rev_list(cmd_opts, container_sha)
        !rev_list.split("\n").grep(index_sha).empty?
      end
      
      def git_command__pull(local_branch, remote_branch, remote_name = nil, force = false)
        remote_name ||= default_remote_name
        args = [cmd_opts, remote_name, "#{remote_branch}:#{local_branch}"]
        args << '-f' if force
        git_command.pull(*args)
      end
      
      def git_command__rebase(branch_name, remote_name = nil)
        remote_name ||= default_remote_name
        git_command.rebase(cmd_opts, "#{remote_name}/#{branch_name}")
      end
      
      # opts can have keys:
      #   :squash
      #   :strategy - can be :theirs
      def git_command__merge(branch_to_merge_from, opts = {})
        command_array = [branch_to_merge_from]
        command_array << '--squash' if opts[:squash]
        if strategy = opts[:strategy]
          case strategy
          when :theirs then command_array += ['-X', 'theirs']
          else fail Error, "Not supported: opts[:strategy]=#{strategy}"
          end
        end
        git_command.merge(cmd_opts, *command_array)
      end
      
      def git_command__hard_reset(branch_to_reset_from =  nil)
        if branch_to_reset_from
          git_command.reset(cmd_opts, '--hard', branch_to_reset_from)
        else
          git_command.reset(cmd_opts, '--hard')
        end
      end
      
      def git_command__create_local_branch(branch_name)
        git_command.branch(cmd_opts, branch_name)
      end

      def git_command__delete_local_branch?(branch_name)
        if get_branches.include?(branch_name)
          git_command__delete_local_branch(branch_name)
        end
      end
      
      def git_command__delete_local_branch(branch_name)
        # hard reset to clear any working memory
        git_command__hard_reset
        git_command.branch(cmd_opts, '-D', branch_name)
      end

      def git_command__delete_remote_branch?(branch_name, remote_name = nil)
        if remote_branch_exists?(branch_name, remote_name)
          git_command__delete_remote_branch(branch_name, remote_name)
        end
      end

      def git_command__delete_remote_branch(branch_name, remote_name)
        remote_name ||= default_remote_name
        git_command.push(cmd_opts, remote_name, ":refs/heads/#{branch_name}")
      end
      
      def cmd_opts
        { raise: true, timeout: 60 }
      end

    end
  end
end
