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
    #  :no_error_if_exists - Boolean (default: false)
    #  :delete_existing_branch - Boolean (default: false)
    #  :no_initial_commit - Boolean (default: false)
    #  :return_module_branch - Boolean (default: false)
    #  :add_remote_files_info - subclass of DTK::RepoManager::AddRemoteFilesInfo
    #  :create_implementation - Boolean (default: false)
    #  :has_remote_repo - Boolean (default: false)
    #  :donot_push_to_repo_manager
    #  :common_module - TODO: see if this is needed and instead use module_type from local_params
    def create_module(project, local_params, opts = {})
      local       = local_params.create_local(project)
      namespace   = local_params.namespace
      module_name = local_params.module_name
      project_idh = project.id_handle

      module_obj = module_exists?(project_idh, module_name, namespace)
      if module_obj and not opts[:no_error_if_exists]
        if opts[:common_module] && module_obj.get_module_branch(local.branch_name)
          full_module_name = Namespace.join_namespace(namespace, module_name)
          fail ErrorUsage, "Module '#{full_module_name}' cannot be created since it exists already"
        end
      end

      local_repo_obj = 
        if module_obj && opts[:common_module]
          if repo = module_obj.get_repo?
            repo.merge!(branch_name: local.branch_name)
            add_branch_opts = { delete_existing_branch: opts[:delete_existing_branch] }
            # TODO: DTK-3232; when bug manifested there where two branches in module_obj.get_module_branches and test picking second
            # had code go through. In this case teh second was the master branch and first was 0.9.1, but cant just pick 
            # base branch in case only semantic version branches are installed
            # In summary 'base_branch just needs to be a random branch  ..' is wrong unbless we change code so any branch works
            # or pick right branch

            # base_branch just needs to be a random branch on module_obj

            # make sure that base_branch has repo_id
            # TODO: is this protection needed because testing bad state db or needed in normal cases
            module_branches    = module_obj.get_module_branches
            unless base_branch = module_branches.select{ |module_branch| module_branch[:repo_id] }.first
              base_branch = module_branches.first
              base_branch[:repo_id] = repo.id
            end

            RepoManager.add_branch_and_push?(local.branch_name, add_branch_opts, base_branch)
            repo.create_subclass_obj(:repo_with_branch)
          else
            create_module__create_repo(local, opts)
          end
        else
          create_module__create_repo(local, opts)
        end

      repo_idh = local_repo_obj.id_handle
      module_and_branch_info = create_module_and_branch_obj?(project, repo_idh, local, opts)

      Implementation.create?(project, local, local_repo_obj) if opts[:create_implementation]

      if opts[:has_remote_repo]
        RepoRemote.create_repo_remote?(project.model_handle(:repo_remote), local.module_name, local_repo_obj.display_name, local.namespace, local_repo_obj.id, set_as_default_if_first: true)
      end

      return module_and_branch_info if opts[:return_module_branch]

      opts_info = { version: local.version, module_namespace: local.namespace }
      module_and_branch_info.merge(module_repo_info: module_repo_info(local_repo_obj, module_and_branch_info, opts_info))
    end
    
    def create_module__create_repo(local, opts = {})
      create_repo_opts = {
        no_initial_commit:  opts[:no_initial_commit],
        add_remote_files_info:  opts[:add_remote_files_info],
        donot_push_to_repo_manager: opts[:donot_push_to_repo_manager],
        delete_if_exists: true
      }
      create_repo(local, create_repo_opts)
    end
    private :create_module__create_repo

    # opts can have keys:
    #   :no_initial_commit
    #   :add_remote_files_info
    #   :delete_if_exists
    #   :donot_push_to_repo_manager
    def create_repo(local, opts = {})
      project_idh = local.project.id_handle
      if opts[:donot_push_to_repo_manager]
        Repo::WithBranch.create_obj?(project_idh.createMH(:repo), local)
      else
        create_opts = {
          create_branch: local.branch_name,
          donot_create_master_branch: true,
          delete_if_exists: opts[:delete_if_exists],
          # TODO: dont think key 'namespace_name' is used
          namespace_name: local.namespace
        }
        create_opts.merge!(push_created_branch: true) unless opts[:no_initial_commit]
        
        if add_remote_files_info = opts[:add_remote_files_info]
          create_opts.merge!(add_remote_files_info: add_remote_files_info)
        end
        Repo::WithBranch.create_actual_repo(project_idh, local, create_opts)
      end
    end

    # opts can have keys
    #  :ancestor_branch_idh
    #  :current_sha
    # TODO: 2575: look at setting new branch dsl_version from branch clone from
    def create_module_and_branch_obj?(project, repo_idh, local, opts = {})
      project_idh = project.id_handle
      module_name = local.module_name
      namespace = Namespace.find_or_create(project.model_handle(:namespace), local.module_namespace_name)
      ref = local.module_name(with_namespace: true)
      mb_create_hash = ModuleBranch.ret_create_hash(repo_idh, local, opts)
      version_field = mb_create_hash.values.first[:version]

      # create module and branch (if needed)
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

      module_branch = get_module_branch_from_local(local)

      return module_branch if opts[:return_module_branch]

      module_idh =  project_idh.createIDH(model_name: model_name, id: module_branch[:module_id])
      # TODO: ModuleBranch::Location: see if after refactor version field needed
      # TODO: ModuleBranch::Location: ones that come from local can be omitted
      { version: version_field, module_name: module_name, module_idh: module_idh, module_branch_idh: module_branch.id_handle }
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
    #   :sha - this is base sha to branch from
    #   :checkout_branch
    #   :delete_existing_branch (Boolean; default: false)
    #   :frozen
    #   :inherit_frozen_from_base
    #   :donot_update_model
    def create_new_version(base_version, new_version, opts = {})
      unless aug_base_branch = get_augmented_module_branch_with_version(base_version)
        fail ErrorUsage.new("There is no module (#{pp_module_ref}) in the workspace")
      end

      # make sure there is a not an existing branch that matches the new one
      if !opts[:delete_existing_branch] and get_module_branch_matching_version(new_version)
        fail VersionExist.new(new_version, pp_module_ref)
      end

      opts_repo_update = Aux.hash_subset(opts, [:sha, :checkout_branch, :delete_existing_branch]).merge(base_version: base_version)
      new_version_repo, new_version_sha, new_branch_name = aug_base_branch.create_new_branch_from_this_branch?(get_project, aug_base_branch.repo, new_version, opts_repo_update)
      
      opts_type_specific_create = opts.merge(
        ancestor_branch_idh: aug_base_branch.id_handle, 
        current_sha: new_version_sha, 
        new_branch_name: new_branch_name,
        dsl_version: aug_base_branch.dsl_version,
        donot_update_model: opts[:donot_update_model]                                             
      )

      if opts[:inherit_frozen_from_base]
        opts_type_specific_create[:frozen] = aug_base_branch[:frozen] if opts_type_specific_create[:frozen].nil?
      end

      new_module_branch = create_new_version__type_specific(new_version_repo, new_version, opts_type_specific_create)
      ModuleRefs.clone_component_module_refs(aug_base_branch, new_module_branch)
      new_module_branch
    end
  end
end; end
