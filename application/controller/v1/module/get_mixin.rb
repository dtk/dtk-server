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
    module GetMixin
      def assemblies
        module_name, namespace, version = request_params(:module_name, :namespace, :version)
        datatype = :assembly_template_with_module

        response =
          if module_name and namespace
            datatype = :assembly_template_description
            ret_service_module.list_assembly_templates(version)
          else
            CommonModule.list_assembly_templates(get_default_project)
          end

        rest_ok_response response, datatype: datatype
      end

      def exists
        namespace, module_name = required_request_params(:namespace, :module_name)

        version     = request_params(:version) || 'master'
        remote_info = request_params(:remote_info)
        response    = CommonModule.exists(get_default_project, namespace, module_name, version, { ret_remote_info: remote_info })

        if remote_info && (response || {})[:has_remote]
          rsa_pub_key   = required_request_params(:rsa_pub_key)
          remote_params = remote_params_dtkn_service_and_component_info(namespace, module_name, version)
          opts          = version ? {} : { ignore_missing_base_version: true }
          remote_info   = CommonModule::Remote.get_module_info(get_default_project, remote_params, rsa_pub_key, opts)
          response.merge!(remote_info) unless remote_info.empty?
        end

        rest_ok_response response
      end

      def list
        opts = Opts.new(remote_repo_base: ret_remote_repo_base)
        datatype  = :module
        if detail_to_include = ret_detail_to_include
          opts.merge!(detail_to_include: detail_to_include)
          datatype  = :module_with_versions if detail_to_include.include?(:versions)
        end
        rest_ok_response CommonModule.list_modules(get_default_project, opts), datatype: datatype
      end

      def module_dependencies
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)
        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        rest_ok_response CommonModule.get_module_dependencies(get_default_project, rsa_pub_key, remote_params)
      end

      def local_module_dependencies
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version)
        local_params = local_params(:component_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.get_local_module_dependencies(get_default_project, local_params)
      end

      def remote_modules
        rsa_pub_key = required_request_params(:rsa_pub_key)
        namespace   = ret_request_params(:module_namespace)
        opts = {
          remote_repo_base: ret_remote_repo_base,
          namespace: ret_request_params(:module_namespace)
        }
        datatype  = :remote_module
        rest_ok_response  CommonModule::Remote.list(rsa_pub_key, opts), datatype: datatype
      end

      def remote_module_info
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)
        remote_params = remote_params_dtkn_service_and_component_info(namespace, module_name, version)
        opts = version ? {} : { ignore_missing_base_version: true }
        rest_ok_response CommonModule::Remote.get_module_info(get_default_project, remote_params, rsa_pub_key, opts)
      end

      def module_info_with_local_dependencies
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version) || 'master'
        response = {}
        if module_info = CommonModule.exists(get_default_project, namespace, module_name, version, { ret_remote_info: true })
          local_params = local_params(:component_module, module_name, namespace: namespace, version: version)
          dependencies = CommonModule.get_local_module_dependencies(get_default_project, local_params)
          response = { :module_info => module_info, :dependencies => dependencies }
        end
        rest_ok_response response
      end

      def get_modules_versions_with_dependencies
        response = {}
        CommonModule.all_modules_with_versions_with_dependencies(get_default_project, response)
        rest_ok_response response
      end

      def versions
        namespace, module_name = required_request_params(:namespace, :module_name)
        rest_ok_response CommonModule.module_versions(get_default_project, namespace, module_name, Opts.new(detail_to_include: [:versions]))
      end
    end
  end
end

