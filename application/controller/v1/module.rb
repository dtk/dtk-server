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
  module V1
    class ModuleController < V1::Base
      helper :module_helper
      # helper :remotes_helper

      LIST_ASSEMBLIES_DATATYPE = :assembly_template_with_module

      def list_assemblies
        project = get_default_project
        rest_ok_response CommonModule.list_assembly_templates(get_default_project), datatype: LIST_ASSEMBLIES_DATATYPE
      end

      def exists
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version)||'master'
        rest_ok_response CommonModule.exists(get_default_project, namespace, module_name, version)
      end

      def get_module_dependencies
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)
        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        rest_ok_response CommonModule.get_module_dependencies(get_default_project, rsa_pub_key, remote_params)
      end

      def install_component_module
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)

        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        local_params  = local_params(:component_module, module_name, namespace: namespace, version: version)

        rest_ok_response CommonModule.install_component_module(get_default_project, local_params, remote_params, rsa_pub_key)
      end

      def install_service_module
        namespace, module_name, content = required_request_params(:namespace, :module_name, :content)
        version = request_params(:version)
        local_params = local_params(:service_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.install_service_module(get_default_project, local_params, content)
      end

      def create_empty_module
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version)
        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.create_empty_module(get_default_project, local_params)
      end

      def update_from_repo
        namespace, module_name, branch, repo_name, commit_sha = required_request_params(:namespace, :module_name, :branch, :repo_name, :commit_sha)
        version = request_params(:version)
        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.update_from_repo(get_default_project, local_params, branch, repo_name, commit_sha, { force_pull: true })
      end

      def delete
        namespace, module_name, = required_request_params(:namespace, :module_name)
        version = request_params(:version)
        rest_ok_response CommonModule.delete(get_default_project, namespace, module_name, version)
      end
    end
  end
end
