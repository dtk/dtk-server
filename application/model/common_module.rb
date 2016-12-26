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
    require_relative('common_module/remote')
    require_relative('common_module/import') #TODO: should this be removed or have name changed after fully port to new client
    require_relative('common_module/module_repo_info')
    require_relative('common_module/update')
    require_relative('common_module/service_info')
    require_relative('common_module/component_info')
    require_relative('common_module/service_instance')

    extend  CommonModule::ClassMixin
    include CommonModule::Mixin

    extend ModuleClassMixin
    include ModuleMixin
    include BaseModule::DeleteMixin

    def self.combined_module_type
      :combined_module
    end

    # opts can have keys:
    #   :has_remote_repo
    def self.create_empty_module_with_branch(project, local_params, opts = {})
      create_module_opts = {
        return_module_branch: true,
        no_initial_commit: true,
        common_module: true,
        has_remote_repo: opts[:has_remote_repo]
      }
      # create_module also creates branch
      module_branch = create_module(project, local_params, create_module_opts)
      ModuleRepoInfo.new(module_branch)
    end

    # opts can have keys
    #  :remote_repo_base
    #  :detail_to_include
    def self.list(project, opts = Opts.new)
      ServiceInfo.list(opts.merge(project_idh: project.id_handle, remove_assembly_branches: true, include_common_modules: true))
    end

    def self.list_assembly_templates(project)
      ServiceInfo.list_assembly_templates(project)
    end

    def self.get_module_dependencies(project, rsa_pub_key, remote_params)
      ComponentInfo.get_module_dependencies(project, rsa_pub_key, remote_params)
    end

    def self.exists(project, module_type, namespace, module_name, version)
      if matching_module = get_class_from_module_type(module_type).find_from_name_with_version?(project, namespace, module_name, version)
        ModuleRepoInfo.new(matching_module[:module_branch])
      end
    end

    def self.get_common_module?(project, namespace, module_name, version)
      find_from_name_with_version?(project, namespace, module_name, version)
    end

    def self.delete(project, namespace, module_name, version, opts = {})
      unless common_module = get_common_module?(project, namespace, module_name, version)
        print_opts = {:namespace => namespace, :version => version}
        fail ErrorUsage.new("DTK module '#{DTK::Common::PrettyPrintForm.module_ref(module_name, opts)}' does not exist!")
      end
      common_module.delete_common_module_version_or_module(version, opts)
    end

    def self.model_type
      :common_module
    end

    private

    def self.get_class_from_module_type(module_type)
      case module_type.to_sym
      when :common_module then CommonModule
      when :service_module then ServiceInfo
      when :component_module then ComponentInfo
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
