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
    class ComponentInfo
      # For installing and pulling component info from dtkn remote
      class Remote
        def initialize(project, local_params, remote_params, client_rsa_pub_key)
          @project             = project
          @local               = local_params.create_local(project)
          @remote              = remote_params.create_remote(project)
          @version             = remote_params.version
          @client_rsa_pub_key  = client_rsa_pub_key
          @remote_repo_handler = Repo::Remote.new(@remote)
          @remote_repo_info    = @remote_repo_handler.get_remote_module_info(client_rsa_pub_key)
          @git_repo_name       = @remote_repo_info[:git_repo_name]

          @remote.set_repo_name!(@git_repo_name)
        end
        private :initialize

        # install from a dtkn repo; directly in this method handles the module/branch and repo level items
        # and then calls process_dsl_and_ret_parsing_errors to handle model and implementaion/files parts 
        def self.install(project, local_params, remote_params, client_rsa_pub_key)
          new(project, local_params, remote_params, client_rsa_pub_key).install
        end
        def install
          Model.Transaction do
            module_obj = module_class.module_exists?(project.id_handle, local_module_name, local.namespace)

            repo_with_branch = 
              if module_obj and module_obj.get_module_branch(local_branch)
                repo = module_obj.get_repo.merge(branch_name: local_branch)
                repo.create_subclass_obj(:repo_with_branch)
              else
                create_repo_with_branch(delete_if_exists: module_obj.nil?)
              end

            commit_sha = repo_with_branch.initial_sync_with_remote(remote, remote_repo_info)
            # create object in object model that corresponds to remote repo
            module_class.create_repo_remote_object(repo_with_branch, remote, git_repo_name)
            
            module_and_branch_info = module_class.create_module_and_branch_obj?(project, repo_with_branch.id_handle, local)
            module_obj ||= module_and_branch_info[:module_idh].create_object
            module_branch = module_and_branch_info[:module_branch_idh].create_object
            
            
            opts_process_dsl = { set_external_refs: true } # only releant for a component module
            # process_dsl_and_ret_parsing_errors will raise error if parsing error
            module_obj.process_dsl_and_ret_parsing_errors(repo_with_branch, module_branch, local, opts_process_dsl)
            module_branch.set_sha(commit_sha)
            module_class.module_repo_info(repo_with_branch, module_and_branch_info, version: version, module_namespace: local_namespace)
          end
        end

        private

        attr_reader :project, :local, :remote, :version, :client_rsa_pub_key, :remote_repo_handler, :remote_repo_info, :git_repo_name

        # opts can have keys 
        #   :delete_if_exists
        def create_repo_with_branch(opts = {})
          remote_repo_handler.authorize_dtk_instance(client_rsa_pub_key) # TODO: see if this is necessary
              
          # create empty repo on local repo manager;
          # need to make sure that tests above indicate whether module exists already since using :delete_if_exists
          create_opts = {
            donot_create_master_branch: true,
            delete_if_exists: opts[:delete_if_exists]
          }
          repo_user_acls = RepoUser.authorized_users_acls(project.id_handle)
          Repo::WithBranch.create_workspace_repo(project.id_handle, local, repo_user_acls, create_opts)
        end

        def local_branch     
          local.branch_name
        end
        
        def local_module_name 
          local.module_name
        end

        def local_namespace  
          local.module_namespace_name
        end

        def set_repo_name_on_remote!(remote_repo_handle)
        end

        def module_class
          ComponentModule
        end
      end
    end
  end
end
