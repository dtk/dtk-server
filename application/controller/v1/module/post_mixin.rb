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
      def stage
        service_module  = ret_service_module
        is_base_service = boolean_request_params(:is_base)
        assembly_name   = request_params(:assembly_name) # could be empty means look for unique assembly in service module

        if version = request_params(:version)
          version = nil if BASE_VERSION_STRING.include?(version)
        else
          version = compute_latest_version(service_module)
        end
        assembly_template = service_module.assembly_template(assembly_name: assembly_name, version: version)

        if service_name = request_params(:service_name)
          fail ErrorUsage, "Service '#{service_name}' exists already" if matches_existing_assembly_instance?(service_name, assembly_template)
        else
          service_name = generate_new_service_name(assembly_template, service_module)
        end

        opts = {
          project: get_default_project,
          service_module: service_module,
          no_auto_complete: boolean_request_params(:no_auto_complete),
          version: version,
          add_nested_modules: true 
        }
        opts = Opts.new(opts)

        response =
          if is_base_service
            Service::Target.stage_base_service(service_name, assembly_template, opts)
          else
            context_assembly_instances = ret_context_assembly_instances
            Service::Target.stage_service(service_name, assembly_template, context_assembly_instances, opts)
          end
        rest_ok_response response
      end
      BASE_VERSION_STRING = ['base', 'master'] #TODO: settle on one

      def generate_service_name
        service_module    = ret_service_module
        assembly_name     = request_params(:assembly_name)

        if version = request_params(:version)
          version = nil if BASE_VERSION_STRING.include?(version)
        else
           version = compute_latest_version(service_module)
        end

        assembly_template = service_module.assembly_template(assembly_name: assembly_name, version: version)
        rest_ok_response generate_new_service_name(assembly_template, service_module)
      end
      
      def create_empty_module
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version) || 'master'
        has_remote_repo = boolean_request_params(:has_remote_repo)

        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.create_empty_module_with_branch(get_default_project, local_params, has_remote_repo: has_remote_repo)
      end

      def create_repo_from_component_info
        namespace, module_name = required_request_params(:namespace, :module_name)
        version = request_params(:version) || 'master'

        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule.create_repo_from_component_info(get_default_project, local_params)
      end

      def delete
        namespace, module_name, = required_request_params(:namespace, :module_name)
        force   = boolean_request_params(:force)
        version = request_params(:version) || 'master'
        opts = { from_common_module: true, force: force }

        rest_ok_response CommonModule.delete(get_default_project, namespace, module_name, version, opts)
      end

      def install_component_info
        fail "TODO: DTK-3366: this route should not be called"
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)

        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        local_params  = local_params(:component_module, module_name, namespace: namespace, version: version)

        CommonModule::Info::Component::Remote.install(get_default_project, local_params, remote_params, rsa_pub_key)
        rest_ok_response 
      end

      def install_service_info
        fail "TODO: DTK-3366: this route should not be called"
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)

        remote_params = remote_params_dtkn(:service_module, namespace, module_name, version)
        local_params  = local_params(:service_module, module_name, namespace: namespace, version: version)

        CommonModule::Info::Service::Remote.install(get_default_project, local_params, remote_params, rsa_pub_key)
        rest_ok_response
      end

      def install_on_server
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)

        local_params  = local_params(:common_module, module_name, namespace: namespace, version: version)
        remote_params = remote_params_dtkn_service_and_component_info(namespace, module_name, version)

        # use latest version if not specified
        unless version
          remote_opts = version ? {} : { ignore_missing_base_version: true }
          response = CommonModule::Remote.get_module_info(get_default_project, remote_params, rsa_pub_key, remote_opts)
          version  = response[:version]
          local_params[:version] = version
          remote_params[:version] = version
        end

        CommonModule::Remote.install_on_server(get_default_project, local_params, remote_params, rsa_pub_key)

        opts = {
          skip_missing_check: false,
          initial_update: true,
          force_parse: true,
          install_on_server: true
        }
        rest_ok_response CommonModule::Update::Module.update_from_repo(get_default_project, nil, local_params, opts)
      end

      def publish_to_remote
        namespace, module_name, version, rsa_pub_key = required_request_params(:namespace, :module_name, :version, :rsa_pub_key)

        local_params  = local_params(:common_module, module_name, namespace: namespace, version: version)
        remote_params = remote_params_dtkn_service_and_component_info(namespace, module_name, version)

        rest_ok_response CommonModule::Remote.publish(get_default_project, local_params, remote_params, rsa_pub_key) 
      end

      def delete_from_remote
        namespace, module_name, version, rsa_pub_key = required_request_params(:namespace, :module_name, :version, :rsa_pub_key)

        opts          = {}
        remote_params = remote_params_dtkn_service_and_component_info(namespace, module_name, version)

        if version.eql?('all')
          versions = required_request_params(:versions)
          opts.merge!(versions: versions)
        end

        rest_ok_response CommonModule::Remote.delete(get_default_project, remote_params, rsa_pub_key, request_params(:force), opts)
      end

      def pull_component_info_from_remote
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version       = request_params(:version)
        force         = boolean_request_params(:force)
        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        local_params  = local_params(:component_module, module_name, namespace: namespace, version: version)

        if common_module = CommonModule.exists(get_default_project, namespace, module_name, version)
          unless common_module[:repo]
            common_local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
            CommonModule.create_repo_from_component_info(get_default_project, common_local_params, dont_set_dsl_parsed: true)
          end
        end

        rest_ok_response CommonModule::Info::Component::Remote.pull(get_default_project, local_params, remote_params, rsa_pub_key, force: force)
      end

      def update_from_repo
        namespace, module_name, commit_sha = required_request_params(:namespace, :module_name, :commit_sha)
        initial_update     = boolean_request_params(:initial_update)
        version            = request_params(:version)
        skip_missing_check = request_params(:skip_missing_check)
        force_parse        = request_params(:force_parse)
        local_params       = local_params(:common_module, module_name, namespace: namespace, version: version)

        opts = {
          skip_missing_check: skip_missing_check,
          initial_update: initial_update,
          force_parse: force_parse
        }
        rest_ok_response CommonModule::Update::Module.update_from_repo(get_default_project, commit_sha, local_params, opts)
      end

    end
  end
end
