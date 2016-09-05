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
      ### For all modules
      def list
        opts = Opts.new(remote_repo_base: ret_remote_repo_base)
        datatype  = :module
        if detail_to_include = ret_detail_to_include
          opts.merge!(detail_to_include: detail_to_include)
          datatype  = :module_with_versions if detail_to_include.include?(:versions)
        end
        rest_ok_response CommonModule.list(get_default_project, opts), datatype: datatype
      end

      ### Module specific

      def exists
        namespace, module_name, module_type = required_request_params(:namespace, :module_name, :module_type)
        version = request_params(:version)||'master'
        rest_ok_response CommonModule.exists(get_default_project, module_type, namespace, module_name, version)
      end

      def list_assemblies
        # TODO: if  module_name, namespace gievn filter on this
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

      def module_dependencies
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)
        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        rest_ok_response CommonModule.get_module_dependencies(get_default_project, rsa_pub_key, remote_params)
      end

      def remote_module_info
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)
        remote_params = remote_params_dtkn(:service_module, namespace, module_name, version)
        rest_ok_response CommonModule.get_remote_module_info(get_default_project, rsa_pub_key, remote_params)
      end
    end
  end
end

