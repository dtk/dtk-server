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
    module Create
      def create_empty_module_repo(project, local_params, opts = {})
        local       = local_params.create_local(project)
        project_idh = project.id_handle()

        create_opts = {
          create_branch: local.branch_name(),
          push_created_branch: true,
          donot_create_master_branch: true,
          delete_if_exists: true,
          namespace_name: local_params.namespace
        }

        repo_user_acls = RepoUser.authorized_users_acls(project_idh)
        local_repo_obj = Repo::WithBranch.create_workspace_repo(project_idh, local, repo_user_acls, create_opts)
        repo_url       = RepoManager.repo_url(local_repo_obj[:repo_name])

        local_repo_obj.merge(repo_url: repo_url)
      end
    end
  end
end