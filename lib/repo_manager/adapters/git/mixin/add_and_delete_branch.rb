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
module DTK
  class RepoManager::Git 
    module Mixin
      module AddAndDeleteBranch
        # returns sha of new branch
        # opts can have keys:
        #  :empty (Booelan; default: false) - Create empty branch
        #  :sha
        #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
        #  :checkout_branch
        #  :delete_existing_branch (Booelan; default: false)
        def add_branch_and_push?(new_branch, opts = {})
          new_branch_sha = nil
          add_branch?(new_branch, opts)
          branch_or_sha = opts[:checkout_branch] ? new_branch : (opts[:sha] || new_branch)
          checkout(branch_or_sha) do
            new_branch_sha = git_command__push(new_branch, nil, nil, force: true)
          end
          new_branch_sha
        end
        
        # opts can have keys:
        #  :empty (Booelan; default: false) - Create empty branch
        #  :sha
        #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
        #  :delete_existing_branch (Booelan; default: false)
        def add_branch?(new_branch, opts = {})
          add_branch = true
          if get_branches.include?(new_branch)
            if opts[:delete_existing_branch]
              delete_local_and_remote_branch(new_branch)
            else
              add_branch = false
            end
          end
          add_branch(new_branch, opts.merge(add_remote_files_info: nil)) if add_branch

          add_remote_files?(new_branch, opts[:add_remote_files_info])
        end
        
        # opts can have keys:
        #  :empty (Booelan; default: false) - Create empty branch
        #  :sha
        #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
        def add_branch(new_branch, opts = {})
          if opts[:empty]
            git_command__change_head_symbolic_ref(new_branch)
            git_command__empty_commit 
          else
            checkout(opts[:sha] || @branch) do
              git_command__add_branch(new_branch)
            end
          end
          add_remote_files?(new_branch, opts[:add_remote_files_info])
        end
        
        def add_remote_files(add_remote_files_info)
          add_remote_files?(@branch, add_remote_files_info)
        end

        def delete_local_and_remote_branch(branch, remote_name = nil)
          checkout_other_branch?(branch) do
            git_command__delete_local_branch?(branch)
            git_command__delete_remote_branch?(branch, remote_name)
          end
        end
        
        private

        # If add_remote_files_info is not nil then it is a subclass of DTK::RepoManager::AddRemoteFilesInfo
        # and we use that to add remote files to the repo branch
        def add_remote_files?(branch, add_remote_files_info)
          return if add_remote_files_info.nil?
          checkout(branch) do 
            add_remote_files_info.add_files(git_repo_manager: self, branch: branch)
          end
          add_all_files(branch) if add_remote_files_info.git_add_needed?
        end

        def checkout_other_branch?(branch, &body)
          if branch != current_branch
            yield
          else
            unless other_branch = get_branches.find { |br| br != branch }
              fail Error.new("Cannot find branch other than '#{branch}' to checkout")
            end
            checkout(other_branch) do        
              yield
            end
          end
        end
 
      end
    end
  end
end
