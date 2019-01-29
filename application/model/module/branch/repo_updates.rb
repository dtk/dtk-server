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
  class ModuleBranch
    module RepoUpdates
      module Mixin
        # returns nil if no changes, otherwise returns Repo::Difs::Summary object
        # opts can have keys:
        #   :force
        def pull_repo_changes_and_return_diffs_summary(commit_sha, opts = {}, &body)
          # RepoManager::Transaction.reset_on_error(self) do
            pull_opts = { force: opts[:force], ret_diffs: nil } #by having key :ret_diffs exist in options it will be set
            if opts[:install_on_server]
              repo_diffs_summary = {}
            else
              pull_from_remote_raise_error_if_merge_needed(pull_opts)
              repo_diffs_summary = pull_opts[:ret_diffs].ret_summary # pull_from_remote_raise_error_if_merge_needed will have set pull_opts[:ret_diffs]
            end
            body.call(repo_diffs_summary)
          # end
        end


        # returns nil if no changes, otherwise returns Repo::Difs::Summary object
        # if change updates sha on object
        # it returns diffs_summary
        # opts can have keys:
        #   :force
        def pull_remote_repo_changes!(remote, opts = {}) 
          RepoManager::Transaction.reset_on_error(self) do 
            opts_fast_foward = {
              force: opts[:force],
              remote_name: remote.remote_ref,
              remote_url: remote.repo_url,
              ret_diffs: nil #by having key :ret_diffs exist in options it will be set
            }
            merge_result = RepoManager.pull_from_remote(remote.branch_name, opts_fast_foward, self)
            case merge_result
            when :merge_needed
              # TODO: DTK-2795: below is wrong want full module ref no just module name
              fail ErrorUsage, "Merge problem pulling changes from remote into module '#{get_module.pp_module_ref}'" if merge_result == :merge_needed
            when :changed
              # this takes changes that are on clone in local server repo and pushes it to the repo
              update_current_sha_from_repo!
              push_changes_to_repo(force: true)
            when :no_change
              #no op
            else fail Error, "Unexpected merge_result '#{merge_result}'"
            end
            
            # RepoManager.pull_from_remote will have updated opts_fast_foward[:ret_diffs]
            opts_fast_foward[:ret_diffs].ret_summary
          end
        end

        COMPONENT_MODULE_REMOTE_NAME = 'component_module'
        def pull_from_component_module!(aug_component_module_branch)
          RepoManager::Transaction.reset_on_error(self) do 
            external_repo   = aug_component_module_branch.repo
            external_branch = aug_component_module_branch.branch_name
            diffs = RepoManager.pull_from_external_repo(external_repo, external_branch, COMPONENT_MODULE_REMOTE_NAME, self)
            update_current_sha_from_repo!
            diffs.ret_summary
          end
        end

        SERVICE_MODULE_REMOTE_NAME = 'service_module'
        def pull_from_service_module!(aug_service_module_branch)
          RepoManager::Transaction.reset_on_error(self) do
            external_repo   = aug_service_module_branch.repo
            external_branch = aug_service_module_branch.branch_name
            diffs = RepoManager.pull_from_external_repo(external_repo, external_branch, SERVICE_MODULE_REMOTE_NAME, self)
            update_current_sha_from_repo!
            diffs.ret_summary
          end
        end

      end
    end
  end
end
