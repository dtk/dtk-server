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
        service_module    = ret_service_module
        is_target_service = boolean_request_params(:is_target)
        assembly_name     = request_params(:assembly_name) # could be empty means look for unique assembly in service module

        if version = request_params(:version)
          version = nil if BASE_VERSION_STRING.include?(version)
        else
           version = compute_latest_version(service_module)
        end
        assembly_template = service_module.assembly_template(assembly_name: assembly_name, version: version)
        service_name = request_params(:service_name) || generate_new_service_name(assembly_template, service_module)

        opts = {
          project: get_default_project,
          service_module: service_module,
          service_name: service_name,
          no_auto_complete: boolean_request_params(:no_auto_complete),
          version: version,
          add_nested_modules: true 
        }
        opts = Opts.new(opts)

        response =
          if is_target_service
            target_name = service_name || "#{service_module[:display_name]}-#{assembly_template[:display_name]}"
            Service::Target.stage_target_service(assembly_template, CommonModule::ServiceInstance, opts.merge(target_name: target_name))
          else
            target_service = ret_target_service_with_default(:target_service, new_client: true)
            # TODO: for testing
            #opts = opts.merge!(allow_existing_service: true)
            target_service.stage_service(assembly_template, CommonModule::ServiceInstance, opts)
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

      def delete
        namespace, module_name, = required_request_params(:namespace, :module_name)
        version = request_params(:version) || 'master'
        opts = { from_common_module: true }
        rest_ok_response CommonModule.delete(get_default_project, namespace, module_name, version, opts)
      end

      def install_component_module
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)

        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        local_params  = local_params(:component_module, module_name, namespace: namespace, version: version)

        rest_ok_response CommonModule::Info::Component::Remote.install(get_default_project, local_params, remote_params, rsa_pub_key)
      end

      def publish_to_remote
        namespace, module_name, version, rsa_pub_key = required_request_params(:namespace, :module_name, :version, :rsa_pub_key)

        local_params  = local_params(:common_module, module_name, namespace: namespace, version: version)
        remote_params = remote_params_dtkn_service_and_component_info(namespace, module_name, version)

        rest_ok_response CommonModule::Remote.publish(get_default_project, local_params, remote_params, rsa_pub_key) 
      end

      def delete_from_remote
        namespace, module_name, version, rsa_pub_key = required_request_params(:namespace, :module_name, :version, :rsa_pub_key)
        remote_params = remote_params_dtkn_service_and_component_info(namespace, module_name, version)
        rest_ok_response CommonModule::Remote.delete(get_default_project, remote_params, rsa_pub_key, false)
      end

      def pull_component_module_from_remote
        namespace, module_name, rsa_pub_key = required_request_params(:namespace, :module_name, :rsa_pub_key)
        version = request_params(:version)

        remote_params = remote_params_dtkn(:component_module, namespace, module_name, version)
        local_params  = local_params(:component_module, module_name, namespace: namespace, version: version)

        response = CommonModule::Info::Component::Remote.pull(get_default_project, local_params, remote_params, rsa_pub_key)
        # TODO: stub so compltes to next step
        diffs_summary = ret_diffs_summary
        component_module = create_obj(:full_module_name, ComponentModule)
        module_dsl_info = component_module.update_model_from_clone_changes?(nil, diffs_summary, version)
        response = module_dsl_info.hash_subset(:dsl_parse_error, :dsl_updated_info, :dsl_created_info, :external_dependencies, :component_module_refs)

        rest_ok_response response
      end

      def update_from_repo
        namespace, module_name, commit_sha = required_request_params(:namespace, :module_name, :commit_sha)
        version = request_params(:version)
        local_params = local_params(:common_module, module_name, namespace: namespace, version: version)
        rest_ok_response CommonModule::Update::Module.update_from_repo(get_default_project, commit_sha, local_params)
      end

    end
  end
end
