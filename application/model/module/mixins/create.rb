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
module DTK; module ModuleMixins
  module Create
  end
  module Create::Class
    def create_module(project, local_params, opts = {})
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

      repo_idh = local_repo_obj.id_handle()
      module_and_branch_info = create_module_and_branch_obj?(project, repo_idh, local)

      opts_info = { version: local.version, module_namespace: local.namespace }
      module_and_branch_info.merge(module_repo_info: module_repo_info(local_repo_obj, module_and_branch_info, opts_info))
    end

    # opts can have keys
    #  :ancestor_branch_idh
    #  :current_sha
    def create_module_and_branch_obj?(project, repo_idh, local, opts = {})
      project_idh = project.id_handle()
      module_name = local.module_name
      namespace = Namespace.find_or_create(project.model_handle(:namespace), local.module_namespace_name)
      ref = local.module_name(with_namespace: true)
      mb_create_hash = ModuleBranch.ret_create_hash(repo_idh, local, opts)
      version_field = mb_create_hash.values.first[:version]

      # create module and branch (if needed)
      fields = {
        display_name: module_name,
        module_branch: mb_create_hash,
        namespace_id: namespace.id()
      }

      create_hash = {
        model_name.to_s() => {
          ref => fields
        }
        }
      input_hash_content_into_model(project_idh, create_hash)

      module_branch = get_module_branch_from_local(local)
      module_idh =  project_idh.createIDH(model_name: model_name(), id: module_branch[:module_id])
      # TODO: ModuleBranch::Location: see if after refactor version field needed
      # TODO: ModuleBranch::Location: ones that come from local can be omitted
      { version: version_field, module_name: module_name, module_idh: module_idh, module_branch_idh: module_branch.id_handle() }
    end

    # TODO: ModuleBranch::Location: deprecate below for above
    def create_ws_module_and_branch_obj?(project, repo_idh, module_name, input_version, namespace, ancestor_branch_idh = nil, opts = {})
      project_idh = project.id_handle()

      ref = Namespace.join_namespace(namespace.display_name(), module_name)
      module_type = model_name.to_s
      create_opts = { version: input_version }
      create_opts.merge!(ancestor_branch_idh: ancestor_branch_idh) if ancestor_branch_idh
      create_opts.merge!(frozen: opts[:frozen]) if opts[:frozen]
      mb_create_hash = ModuleBranch.ret_workspace_create_hash(project, module_type, repo_idh, create_opts)
      version = mb_create_hash.values.first[:version]

      fields = {
        display_name: module_name,
        module_branch: mb_create_hash,
        namespace_id: namespace.id()
      }

      create_hash = {
        model_name.to_s => {
          ref => fields
        }
      }

      input_hash_content_into_model(project_idh, create_hash)

      module_branch = get_workspace_module_branch(project, module_name, version, namespace)
      module_idh =  project_idh.createIDH(model_name: model_name(), id: module_branch[:module_id])
      { version: version, module_name: module_name, module_idh: module_idh, module_branch_idh: module_branch.id_handle() }
    end
  end

  module Create::Instance
    # returns new module branch
    # opts can have keys:
    #  :sha - this is base sha to branch from
    def create_new_version(base_version, new_version, opts = {})
      unless aug_base_branch = get_augmented_workspace_branch(Opts.new(filter: { version: base_version }))
        fail ErrorUsage.new("There is no module (#{pp_module_name()}) in the workspace")
      end

      # make sure there is a not an existing branch that matches the new one
      if get_module_branch_matching_version(new_version)
        fail VersionExist.new(new_version, pp_module_name)
      end

      opts_repo_update = Aux.hash_subset(opts, [:sha, :base_version, :version_branch, :checkout_branch])
      new_version_repo, new_version_sha, new_branch_name = aug_base_branch.create_new_branch_from_this_branch?(get_project(), aug_base_branch[:repo], new_version, opts_repo_update)
      opts_create_branch = opts.merge(ancestor_branch_idh: aug_base_branch.id_handle(), current_sha: new_version_sha, new_branch_name: new_branch_name)

      if opts[:inherit_frozen_from_base]
        opts_create_branch.merge!(frozen: aug_base_branch[:frozen])
      end

      new_branch = create_new_version__type_specific(new_version_repo, new_version, opts_create_branch)
      ModuleRefs.clone_component_module_refs(aug_base_branch, new_branch)
      new_branch
    end
  end
end; end