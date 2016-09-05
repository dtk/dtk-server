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
  class V1::ModuleController
    module PostMixin
      ### Module specific
      def create_empty_module
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version) || 'master'
        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.create_empty_module(get_default_project, local_params)
      end

      def delete
        namespace, module_name, = required_request_params(:namespace, :module_name)
        version = request_params(:version) || 'master'
        rest_ok_response CommonModule.delete(get_default_project, namespace, module_name, version)
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

      def update_from_repo
        namespace, module_name, repo_name, commit_sha = required_request_params(:namespace, :module_name, :repo_name, :commit_sha)
        version = request_params(:version)
        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        opts = { local_params: local_params, repo_name: repo_name, force_pull: true }
        rest_ok_response CommonModule.update_from_repo(:base_service, get_default_project, commit_sha, opts)
      end

    end
  end
end
