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
  class Node_moduleController < AuthController
    helper :module_helper

    #### create and delete actions ###
    def rest__create
      module_name = ret_non_null_request_params(:module_name)
      project = get_default_project()
      version = nil #TODO: stub
      local_params = local_params(:node_module, module_name, version: version)
      module_repo_info = NodeModule.create_module(project, local_params)[:module_repo_info]

      rest_ok_response module_repo_info
    end

    def rest__update_from_initial_create
      node_module = create_obj(:node_module_id)
      repo_id, commit_sha = ret_non_null_request_params(:repo_id, :commit_sha)
      repo_idh = id_handle(repo_id, :repo)
      version = ret_version()
      scaffold = ret_request_params(:scaffold_if_no_dsl)
      opts = { scaffold_if_no_dsl: scaffold, do_not_raise: true, process_provider_specific_dependencies: false }
      rest_ok_response node_module.import_from_file(commit_sha, repo_idh, version, opts)
    end

    def rest__update_model_from_clone
      node_module = create_obj(:node_module_id)
      commit_sha = ret_non_null_request_params(:commit_sha)
      version = ret_version()
      diffs_summary = ret_diffs_summary()
      opts =  {}
      if ret_request_param_boolean(:internal_trigger)
        opts.merge!(do_not_raise: true)
      end
      if ret_request_param_boolean(:force_parse)
        opts.merge!(force_parse: true)
      end
      dsl_created_info = node_module.update_model_from_clone_changes?(commit_sha, diffs_summary, version, opts)
      rest_ok_response dsl_created_info
    end

    def rest__delete
      node_module = create_obj(:node_module_id)
      module_info = node_module.delete_object()
      rest_ok_response module_info
    end

    def rest__delete_version
      node_module = create_obj(:node_module_id)
      version = ret_version()
      module_info = node_module.delete_version(version)
      rest_ok_response module_info
    end

    #### end: create and delete actions ###

    #### list and info actions ###
    def rest__list
      diff             = ret_request_params(:diff)
      project          = get_default_project()
      datatype         = :module
      remote_repo_base = ret_remote_repo_base()

      opts = Opts.new(project_idh: project.id_handle())
      if detail = ret_request_params(:detail_to_include)
        opts.merge!(detail_to_include: detail.map(&:to_sym))
      end

      opts.merge!(remote_repo_base: remote_repo_base, diff: diff)
      datatype = :module_diff if diff

      rest_ok_response NodeModule.list(opts), datatype: datatype
    end

    def rest__get_workspace_branch_info
      node_module = create_obj(:node_module_id)
      version = ret_version()
      rest_ok_response node_module.get_workspace_branch_info(version)
    end

    def rest__info
      module_id = ret_request_param_id_optional(:node_module_id, ::DTK::NodeModule)
      project   = get_default_project()
      opts      = Opts.new(project_idh: project.id_handle())
      rest_ok_response NodeModule.info(model_handle(), module_id, opts)
    end

    def rest__pull_from_remote
      rest_ok_response pull_from_remote_helper(NodeModule)
    end

    def rest__remote_chmod
      response = chmod_from_remote_helper()
      rest_ok_response(response)
    end

    def rest__remote_chown
      chown_from_remote_helper()
      rest_ok_response
    end

    def rest__confirm_make_public
      rest_ok_response confirm_make_public_helper()
    end

    def rest__remote_collaboration
      collaboration_from_remote_helper()
      rest_ok_response
    end

    def rest__list_remote_collaboration
      response = list_collaboration_from_remote_helper()
      rest_ok_response response
    end

    def rest__versions
      node_module = create_obj(:node_module_id)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()
      opts = Opts.new(project_idh: project.id_handle())

      rest_ok_response node_module.local_and_remote_versions(client_rsa_pub_key, opts)
    end

    def rest__info_about
      node_module = create_obj(:node_module_id)
      about = ret_non_null_request_params(:about).to_sym
      component_template_id = ret_request_params(:component_template_id)
      unless AboutEnum.include?(about)
        fail ErrorUsage::BadParamValue.new(:about, AboutEnum)
      end
      rest_ok_response node_module.info_about(about, component_template_id)
    end

    AboutEnum = [:components, :attributes, :instances]

    #### end: list and info actions ###

    #### actions to interact with remote repos ###
    # TODO: rename; this is just called by install; import ops call create route
    def rest__import
      rest_ok_response install_from_dtkn_helper(:node_module)
    end

    # TODO: rename; this is just called by publish
    def rest__export
      node_module = create_obj(:node_module_id)
      rest_ok_response publish_to_dtkn_helper(node_module)
    end

    # this should be called when the module is linked, but the specfic version is not
    def rest__import_version
      node_module = create_obj(:node_module_id)
      remote_repo = ret_remote_repo()
      version = ret_version()
      rest_ok_response node_module.import_version(remote_repo, version)
    end

    # TODO: ModuleBranch::Location: harmonize this signature with one for service module
    def rest__delete_remote
      remote_module_name = ret_non_null_request_params(:remote_module_name)
      remote_namespace = ret_request_params(:remote_module_namespace)
      force_delete = ret_request_param_boolean(:force_delete)

      remote_params = remote_params_dtkn(:node_module, remote_namespace, remote_module_name)
      client_rsa_pub_key = ret_request_params(:rsa_pub_key)
      project = get_default_project()

      NodeModule.delete_remote(project, remote_params, client_rsa_pub_key, force_delete)
      rest_ok_response
    end

    def rest__list_remote
      rest_ok_response NodeModule.list_remotes(model_handle, ret_request_params(:rsa_pub_key)), datatype: :module_remote
    end

    # get remote_module_info; throws an access rights usage error if user does not have access
    def rest__get_remote_module_info
      node_module = create_obj(:node_module_id)
      rest_ok_response get_remote_module_info_helper(node_module)
    end

    #### end: actions to interact with remote repo ###
  end
end