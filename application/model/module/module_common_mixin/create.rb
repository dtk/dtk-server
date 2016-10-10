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
module DTK; module ModuleCommonMixin
  module Create
  end
  module Create::Class
    # opts can have keys
    #  :no_error_if_exists - Booelean (default: false)
    #  :no_initial_commit - Booelean (default: false)
    #  :return_module_branch - Boolean (default: false)
    #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
    def create_module(project, local_params, opts = {})
      local = local_params.create_local(project)
      namespace = local_params.namespace
      module_name = local_params.module_name
      project_idh = project.id_handle

      module_obj = module_exists?(project_idh, module_name, namespace)
      if module_obj and not opts[:no_error_if_exists]
        if opts[:common_module] && module_obj.get_module_branch(local.branch_name)
          full_module_name = Namespace.join_namespace(namespace, module_name)
          fail ErrorUsage, "Module '#{full_module_name}' cannot be created since it exists already"
        end
      end


      if module_obj && opts[:common_module]
        # Aldin TODO: need to find better way to add additional branch to repo
        base_branch = module_obj.get_module_branches.first
        repo = module_obj.get_repo
        repo.merge!(branch_name: local.branch_name)
        RepoManager.add_branch_and_push?(local.branch_name, {}, base_branch)
        local_repo_obj = repo.create_subclass_obj(:repo_with_branch)
      else
        create_opts = {
          create_branch: local.branch_name,
          donot_create_master_branch: true,
          delete_if_exists: true,
          # TODO: dont think key 'namespace_name' is used
          namespace_name: namespace
        }
        create_opts.merge!(push_created_branch: true) unless opts[:no_initial_commit]

        if add_remote_files_info = opts[:add_remote_files_info]
          create_opts.merge!(add_remote_files_info: add_remote_files_info)
        end
        repo_user_acls = RepoUser.authorized_users_acls(project_idh)
        local_repo_obj = Repo::WithBranch.create_workspace_repo(project_idh, local, repo_user_acls, create_opts)
      end

      repo_idh = local_repo_obj.id_handle()
      module_and_branch_info = create_module_and_branch_obj?(project, repo_idh, local, opts)

      return module_and_branch_info if opts[:return_module_branch]

      opts_info = { version: local.version, module_namespace: local.namespace }
      module_and_branch_info.merge(module_repo_info: module_repo_info(local_repo_obj, module_and_branch_info, opts_info))
    end

    # opts can have keys
    #  :ancestor_branch_idh
    #  :current_sha
    # TODO: 2575: look at setting new branch dsl_version from branch clone from
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
        model_type.to_s() => {
          ref => fields
        }
      }
      input_hash_content_into_model(project_idh, create_hash)

      module_branch = get_module_branch_from_local(local)

      return module_branch if opts[:return_module_branch]

      module_idh =  project_idh.createIDH(model_name: model_name(), id: module_branch[:module_id])
      # TODO: ModuleBranch::Location: see if after refactor version field needed
      # TODO: ModuleBranch::Location: ones that come from local can be omitted
      { version: version_field, module_name: module_name, module_idh: module_idh, module_branch_idh: module_branch.id_handle() }
    end

    # TODO: ModuleBranch::Location: deprecate below for above
    # opts can have keys
    #   :dsl_version (required)
    #   :frozen
    #   :ancestor_branch_idh
    #   :return_module_branch - Boolean (default: false)
    def create_ws_module_and_branch_obj?(project, repo_idh, module_name, input_version, namespace, opts = {})
      project_idh = project.id_handle

      ref = Namespace.join_namespace(namespace.display_name, module_name)
      module_type = model_type.to_s
      create_opts = { 
        version: input_version,
        ancestor_branch_idh: opts[:ancestor_branch_idh],
        frozen: opts[:frozen],
        dsl_version: opts[:dsl_version]
      }
      mb_create_hash = ModuleBranch.ret_workspace_create_hash(project, module_type, repo_idh, create_opts)
      version = mb_create_hash.values.first[:version]

      fields = {
        display_name: module_name,
        module_branch: mb_create_hash,
        namespace_id: namespace.id
      }

      create_hash = {
        model_type.to_s => {
          ref => fields
        }
      }

      input_hash_content_into_model(project_idh, create_hash)

      module_branch = get_workspace_module_branch(project, module_name, version, namespace)
      return module_branch if opts[:return_module_branch]

      module_idh =  project_idh.createIDH(model_name: model_name, id: module_branch[:module_id])
      { version: version, module_name: module_name, module_idh: module_idh, module_branch_idh: module_branch.id_handle }
    end
  end

  module Create::Instance
    # Creates a new repo and repo branch if needed from base version and creates abd returns teh associated new module branch
    # It does specfic processing dependending on module type
    # opts can have keys:
    #  :sha - this is base sha to branch from
    #  :version_branch #TODO: see if still used
    #  :base_version
    #  :checkout_branch
    #  :delete_existing_branch (Boolean; default: false)
    def create_new_version(base_version, new_version, opts = {})
      unless aug_base_branch = get_augmented_workspace_branch(Opts.new(filter: { version: base_version }))
        fail ErrorUsage.new("There is no module (#{pp_module_name}) in the workspace")
      end

      # make sure there is a not an existing branch that matches the new one
      if get_module_branch_matching_version(new_version)
        fail VersionExist.new(new_version, pp_module_name)
      end

      opts_repo_update = Aux.hash_subset(opts, [:sha, :base_version, :version_branch, :checkout_branch, :delete_existing_branch])
      new_version_repo, new_version_sha, new_branch_name = aug_base_branch.create_new_branch_from_this_branch?(get_project, aug_base_branch[:repo], new_version, opts_repo_update)
      
      opts_create_branch = opts.merge(
        ancestor_branch_idh: aug_base_branch.id_handle, 
        current_sha: new_version_sha, 
        new_branch_name: new_branch_name,
        dsl_version: aug_base_branch.dsl_version
      )

      if opts[:inherit_frozen_from_base]
        opts_create_branch.merge!(frozen: aug_base_branch[:frozen])
      end

      new_branch = create_new_version__type_specific(new_version_repo, new_version, opts_create_branch)
      ModuleRefs.clone_component_module_refs(aug_base_branch, new_branch)
      new_branch
    end
  end
end; end
