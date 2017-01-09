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
    module Info
      # Base class for getting remote info for component and serviceinfo
      class Remote
        # opts can have keys
        #   :remote_exists - set to true by operations where remote exists
        def initialize(project, local_params, remote_params, client_rsa_pub_key, opts = {})
          @project             = project
          @local               = local_params.create_local(project)
          @remote              = ret_remote(project, remote_params)
          @client_rsa_pub_key  = client_rsa_pub_key
          @remote_repo_handler = Repo::Remote.new(@remote)
          
          if opts[:remote_exists]
            @remote_repo_info    = @remote_repo_handler.get_remote_module_info(client_rsa_pub_key)
            @git_repo_name       = @remote_repo_info[:git_repo_name]
            @remote.set_repo_name!(@git_repo_name)
          end
        end
        private :initialize

        def self.get_module_info?(project, client_rsa_pub_key, remote_params, opts = {})
          remote = ret_remote(project, remote_params)
          Repo::Remote.new(remote).get_remote_module_info?(client_rsa_pub_key, opts)
        end

        def self.publish?(project, local_params, remote_params, client_rsa_pub_key)
          new(project, local_params, remote_params, client_rsa_pub_key).publish?
        end

        private

        attr_reader :project, :local, :remote, :client_rsa_pub_key, :remote_repo_handler, :remote_repo_info, :git_repo_name

        def self.ret_remote(project, remote_params)
          remote_params.create_remote(project, info_type: info_type)
        end
        def ret_remote(project, remote_params)
          self.class.ret_remote(project, remote_params)
        end

        def get_module_branch?
          module_obj? && module_obj?.get_module_branch(local_branch)
        end

        def get_repo_with_branch
          get_repo_with_branch? || fail(Error, "Unexpected that get_repo_with_branch? is nil")
        end

        def get_repo_with_branch?
          if get_module_branch?
            repo = module_obj?.get_repo.merge(branch_name: local_branch)
            repo.create_subclass_obj(:repo_with_branch)
          end
        end

        def create_repo_with_branch
          remote_repo_handler.authorize_dtk_instance(client_rsa_pub_key) # TODO: see if this is necessary
              
          # create empty repo on local repo manager;
          # need to make sure that tests above indicate whether module exists already since using :delete_if_exists
          create_opts = {
            donot_create_master_branch: true,
            delete_if_exists: module_obj?.nil?
          }
          repo_user_acls = RepoUser.authorized_users_acls(project.id_handle)
          Repo::WithBranch.create_workspace_repo(project.id_handle, local, repo_user_acls, create_opts)
        end

        def module_obj
          module_obj? || fail(Error, "unexpected that  module_obj? is nil")
        end

        def module_obj? 
          if @module_obj_computed
            @module_obj
          else
            @module_obj_computed = true
            @module_obj = module_class.module_exists?(project.id_handle, module_name, namespace)
          end
        end

        MASTER_BRANCH_NAME = 'master'
        def is_master_branch?
          version.nil? or version == MASTER_BRANCH_NAME 
        end

        def local_branch     
          local.branch_name
        end
        
        def module_name 
          local.module_name
        end

        def namespace  
          local.module_namespace_name
        end

        def version
          local.version
        end

      end
    end
  end
end
