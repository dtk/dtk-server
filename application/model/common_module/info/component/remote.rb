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
  class CommonModule
    class Info::Component
      # For installing and pulling component info from dtkn remote
      class Remote < Info::Remote

        # install from a dtkn repo; directly in this method handles the module/branch and repo level items
        # and then calls process_dsl_and_ret_parsing_errors to handle model and implementaion/files parts 
        def self.install(project, local_params, remote_params, client_rsa_pub_key)
          new(project, local_params, remote_params, client_rsa_pub_key, remote_exists: true).install
        end

        def self.pull(project, local_params, remote_params, client_rsa_pub_key)
          new(project, local_params, remote_params, client_rsa_pub_key, remote_exists: true).pull
        end

        # returns true if component info is published
        def publish?
          unless module_branch = get_module_branch?
            return nil
          end

          repo                 = get_repo_with_branch
          dsl_file_obj         = CommonDSL::Parse.matching_common_module_top_dsl_file_obj?(commom_module_branch)
          parsed_common_module = dsl_file_obj.parse_content(:common_module)

          # this means component_defs part is deleted from module
          return unless parsed_common_module[:component_defs]

          response = module_obj.publish_info(module_branch, repo, remote, local, client_rsa_pub_key)

          true
        end

        def install
          Model.Transaction do
            # These calls use/create a component module and branch
            repo_with_branch = get_repo_with_branch? || create_repo_with_branch

            commit_sha = repo_with_branch.initial_sync_with_remote(remote, remote_repo_info)

            # create object in object model that corresponds to remote repo
            module_class.create_repo_remote_object(repo_with_branch, remote, git_repo_name)
            
            module_and_branch_info = module_class.create_module_and_branch_obj?(project, repo_with_branch.id_handle, local)
            module_obj ||= module_and_branch_info[:module_idh].create_object
            module_branch = module_and_branch_info[:module_branch_idh].create_object
            
            opts_process_dsl = { set_external_refs: true } # only relevant for a component module
            # process_dsl_and_ret_parsing_errors will raise error if parsing error
            module_obj.process_dsl_and_ret_parsing_errors(repo_with_branch, module_branch, local, opts_process_dsl)
            module_branch.set_sha(commit_sha)

            # This last call creates common module and branch 
            # TODO: DTK-2852: need to change create_empty_module_with_branch to also update content from component module repo
            # or instead to not create any repos here and instaed do it on demand when there is a clone module operation
            CommonModule.create_empty_module_with_branch(project, local_params.merge(module_type: :common_module))
            nil
          end
        end

        # opts can have keys
        #   :force
        def pull(opts = {})
          fail ErrorUsage, "Component module '#{local.pp_module_ref}' cannot be pulled; just 'master' version" unless is_master_branch?
          unless module_branch = get_module_branch?
            fail ErrorUsage, "Component module '#{local.pp_module_ref}' does not exist"
          end

          Model.Transaction do
            unless repo_diffs_summary = module_branch.pull_remote_repo_changes_and_return_diffs_summary(remote, force: opts[:force])
              pp [:repo_diffs_summary, repo_diffs_summary]
              Log.error("Call code to parse if repo_diffs_summary includes the dsl file")
            end
            nil
          end
        end

        private

        def self.info_type
          Info::Component.info_type
        end

        def module_class
          ComponentModule
        end

        def commom_module_branch
          CommonModule.matching_module_branch?(project, namespace, module_name, version) || fail(Error, "Unexpecetd that CommonModule.matching_module_branch? is nil") 
        end
      end
    end
  end
end
