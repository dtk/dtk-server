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
    class Info::Service
      class Remote < Info::Remote
        # returns true if service info is published
        def publish?
          unless module_branch = get_module_branch?
            return nil # no service info
          end

          repo                 = get_repo_with_branch
          dsl_file_obj         = CommonDSL::Parse.matching_common_module_top_dsl_file_obj?(common_module_branch)
          parsed_common_module = dsl_file_obj.parse_content(:common_module)

          # this means assemblies part is deleted from module
          return unless parsed_common_module[:assemblies]

          CommonDSL::Parse.set_dsl_version!(common_module_branch, parsed_common_module)

          args = [project, local, nil, common_module_branch, parsed_common_module, {}]
          file_path__content_array = CommonModule::Update::Module::Info::Service.new(*args).transform_from_common_module?

          RepoManager.add_files(module_branch, file_path__content_array)
          module_obj.publish_info(module_branch, repo, remote, local, client_rsa_pub_key)

          true
        end

        def self.install(project, local_params, remote_params, client_rsa_pub_key)
          new(project, local_params, remote_params, client_rsa_pub_key, remote_exists: true).install
        end

        def install
          Model.Transaction do
            # These calls use/create a service module and branch
            repo_with_branch = get_repo_with_branch? || create_repo_with_branch_if_needed

            commit_sha = repo_with_branch.initial_sync_with_remote(remote, remote_repo_info)

            # create object in object model that corresponds to remote repo
            module_class.create_repo_remote_object(repo_with_branch, remote, git_repo_name)

            module_and_branch_info = module_class.create_module_and_branch_obj?(project, repo_with_branch.id_handle, local)
            module_obj ||= module_and_branch_info[:module_idh].create_object
            module_branch = module_and_branch_info[:module_branch_idh].create_object
            module_branch.set_dsl_parsed!(false)

            # process_dsl_and_ret_parsing_errors will raise error if parsing error
            # module_obj.process_dsl_and_ret_parsing_errors(repo_with_branch, module_branch, local, set_external_refs: true)
            module_branch.set_sha(commit_sha)

            # This last call creates common module and branch
            common_module_branch = CommonModule.create_module_and_branch_obj?(project, nil, local.merge(module_type: :common_module), return_module_branch: true)

            module_branch.set_dsl_parsed!(true)
            common_module_branch.set_dsl_parsed!(true)
            nil
          end
        end

        private
        
        def self.info_type
          Info::Service.info_type
        end

        def module_class
          ServiceModule
        end

      end
    end
  end
end
