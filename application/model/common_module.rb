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
  class CommonModule < Model
    # Mixins must go first
    require_relative('common_module/mixin')
    require_relative('common_module/class_mixin')
    require_relative('common_module/dsl') 
    require_relative('common_module/import')
    require_relative('common_module/module_repo_info') 
    require_relative('common_module/update') 
    require_relative('common_module/base_service') 
    require_relative('common_module/base_component')
    require_relative('common_module/service_instance')

    extend  CommonModule::ClassMixin
    include CommonModule::Mixin

    extend ModuleClassMixin
    include ModuleMixin
    include BaseModule::DeleteMixin

    def self.create_empty_module(project, local_params)
      create_module_opts = {
        return_module_branch: true,
        no_initial_commit: true,
      }
      module_branch = create_module(project, local_params, create_module_opts)
      ModuleRepoInfo.new(module_branch)
    end

    def self.list_assembly_templates(project)
      BaseService.list_assembly_templates(project)
    end

    def self.get_module_dependencies(project, rsa_pub_key, remote_params)
      BaseComponent.get_module_dependencies(project, rsa_pub_key, remote_params)
    end

    def self.install_component_module(project, local_params, remote_params, dtk_client_pub_key)
      BaseComponent.install_module(project, local_params, remote_params, dtk_client_pub_key)
    end

    def self.exists(project, module_type, namespace, module_name, version)
      if matching_module = get_class_from_type(module_type).find_from_name_with_version?(project, namespace, module_name, version)
        ModuleRepoInfo.new(matching_module[:module_branch])
      end
    end

    def self.get_common_module?(project, namespace, module_name, version)
      find_from_name_with_version?(project, namespace, module_name, version)
    end

    # opts can have keys
    #   :force_pull - Boolean (default false) 
    #   :force_parse - Boolean (default false) 
    def self.update_from_repo(common_module_type, project, local_params, repo_name, commit_sha, opts = {})
      Update.update_class(common_module_type).update_from_repo(project, local_params, repo_name, commit_sha, opts)
    end

    def self.delete(project, namespace, module_name, version)
      unless common_module = get_common_module?(project, namespace, module_name, version)
        fail ErrorUsage.new("DTK module '#{namespace}:#{module_name}' does not exist!")
      end
      delete_associated_service_module(common_module)
      common_module.delete_object(skip_validations: true)
    end

    def self.delete_associated_service_module(common_module)
      if service_module = BaseService.find_from_name?(common_module.model_handle(:service_module), common_module.module_namespace, common_module.module_name)
        service_module.delete_object()
      end
    end

    def self.model_type
      :common_module
    end

    private

    def self.get_class_from_type(module_type)
      case module_type.to_sym
      when :common_module then CommonModule
      when :service_module then BaseService
      when :component_module then BaseComponent
      else fail ErrorUsage.new("Unknown module type '#{module_type}'.")
      end
    end

    def self.create_local_params(module_type, module_name, opts = {})
      version   = opts[:version]
      namespace = opts[:namespace] || default_local_namespace_name()
      ModuleBranch::Location::LocalParams::Server.new(
        module_type: module_type,
        module_name: module_name,
        version:     version,
        namespace:   namespace
      )
    end
  end
end
