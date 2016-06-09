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
  module CommonModule
    module ClassMixin
      def find_from_name_with_version?(project, namespace, module_name, version)
        project_mh = project.model_handle
        namespace_obj = Namespace.find_by_name(project_mh.createMH(:namespace), namespace)

        sp_hash = {
          cols: [
            :id,
            :display_name,
            :namespace_id,
            :namespace,
            :version_info
          ],
          filter: [
            :and,
            [:eq, :project_project_id, project.id()],
            [:eq, :namespace_id, namespace_obj.id()],
            [:eq, :display_name, module_name]
          ]
        }

        get_objs(project_mh.createMH(model_type()), sp_hash).find{ |mod| (mod[:module_branch]||{})[:version] == version }
      end

      # TODO: DTK-2583: This is copied from dtk-server/application/model/module/module_common_mixin/create.rb create_module method
      def create_empty_module(project, local_params, opts = {})
        local = local_params.create_local(project)
        namespace = local_params.namespace
        module_name = local_params.module_name
        project_idh = project.id_handle()

        module_exists = module_exists?(project_idh, module_name, namespace)
        if module_exists and not opts[:no_error_if_exists]
          full_module_name = Namespace.join_namespace(namespace, module_name)
          fail ErrorUsage.new("Module (#{full_module_name}) cannot be created since it exists already")
        end

        create_opts = {
          create_branch: local.branch_name(),
          push_created_branch: true,
          donot_create_master_branch: true,
          delete_if_exists: true,
          namespace_name: namespace
        }

        if copy_files_info = opts[:copy_files]
          create_opts.merge!(copy_files: copy_files_info)
        end

        repo_user_acls = RepoUser.authorized_users_acls(project_idh)
        local_repo_obj = Repo::WithBranch.create_workspace_repo(project_idh, local, repo_user_acls, create_opts)

        ModuleRepoInfo.new(create_module_and_branch_obj?(project, local_repo_obj.id_handle(), local))
      end

      # TODO: DTK-2583: This is copied from dtk-server/application/model/module/module_common_mixin/create.rb create_module_and_branch_obj? method
      def create_module_and_branch_obj?(project, repo_idh, local, opts = {})
        namespace      = Namespace.find_or_create(project.model_handle(:namespace), local.module_namespace_name)
        ref            = local.module_name(with_namespace: true)
        mb_create_hash = ModuleBranch.ret_create_hash(repo_idh, local, opts)

        # create module and branch (if needed)
        fields = {
          display_name: local.module_name,
          module_branch: mb_create_hash,
          namespace_id: namespace.id()
        }

        create_hash = {
          model_type.to_s() => {
            ref => fields
          }
        }
        input_hash_content_into_model(project.id_handle(), create_hash)

        get_module_branch_from_local(local)
      end
    end
  end
end
