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
    require_relative('common_module/module_repo_info')
    require_relative('common_module/service')
    require_relative('common_module/component')
    require_relative('common_module/create')

    extend  CommonModule::ClassMixin
    include CommonModule::Mixin
    extend CommonModule::Create

    extend ModuleClassMixin
    # extend AutoImport
    include ModuleMixin
    # extend DSLClassMixin
    # include DSLMixin
    # include ModuleRefs::Mixin

    def self.list_assembly_templates(project)
      Service::Template.list_assembly_templates(project)
    end

    def self.get_module_dependencies(project, rsa_pub_key, remote_params)
      Component::Template.get_module_dependencies(project, rsa_pub_key, remote_params)
    end

    def self.install_component_module(project, local_params, remote_params, dtk_client_pub_key)
      Component::Template.install_module(project, local_params, remote_params, dtk_client_pub_key)
    end

    def self.exists(project, namespace, module_name, version)
      if service = Service::Template.find_from_name_with_version?(project, namespace, module_name, version)
        { service_module_id: service.id() }
      elsif component = Component::Template.find_from_name_with_version?(project, namespace, module_name, version)
        { component_module_id: component.id() }
      end
    end

    def self.create_empty_module(project, local_params, opts = {})
      module_branch = create_module(project, local_params, opts.merge(return_module_branch: true))
      ModuleRepoInfo.new(module_branch)
    end

    def self.update_from_repo(project, local_params, branch, repo_name, commit_sha, opts = {})
      namespace     = Namespace.find_by_name(project.model_handle.createMH(:namespace), local_params.namespace)
      module_branch = get_workspace_module_branch(project, local_params.module_name, local_params.version, namespace, opts)

      module_branch.pull_repo_changes?(commit_sha, true)

      # TODO: Aldin - continue with update_from_clone and probably refactor
    end

    def self.model_type
      :common_module
    end

    private

    def self.get_class_from_type(module_type)
      case module_type.to_sym
      when :common_module then CommonModule
      when :service_module then Service::Template
      when :component_module then Component::Template
      else fail ErrorUsage.new("Unknown module type '#{module_type}'.")
      end
    end
  end
end
