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
    require_relative('common_module/import')
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

    def self.create_empty_module_with_branch(project, local_params)
      create_module_opts = {
        return_module_branch: true,
        no_initial_commit: true,
        common_module: true
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

    def self.list_remotes(project, opts = {})
      rsa_pub_key = opts[:rsa_pub_key]
      Repo::Remote.new.list_module_info(:service_module, rsa_pub_key, opts.merge!(ret_versions_array: true))
    end

    def self.get_module_dependencies(project, rsa_pub_key, remote_params)
      ComponentInfo.get_module_dependencies(project, rsa_pub_key, remote_params)
    end

    def self.get_remote_module_info(project, rsa_pub_key, remote_params)
      ret = {}
      if raw_service_info = ServiceInfo.get_remote_module_info?(project, rsa_pub_key, remote_params)
        ret.merge!(service_info: transform_from_raw_remote_module_info(raw_service_info))
      end
      if raw_component_info = ComponentInfo.get_remote_module_info?(project, rsa_pub_key, remote_params)
        ret.merge!(component_info: transform_from_raw_remote_module_info(raw_component_info))
      end
      if ret.empty?
        fail ErrorUsage, "Module '#{remote_params.pp_module_ref}' not found in the DTKN Catalog"
      end
      ret.merge(version: remote_params.version || intersect_versions(raw_service_info, raw_component_info))
    end

    def self.install_component_module(project, local_params, remote_params, dtk_client_pub_key)
      ComponentInfo.install_module(project, local_params, remote_params, dtk_client_pub_key)
    end

    def self.exists(project, module_type, namespace, module_name, version)
      if matching_module = get_class_from_module_type(module_type).find_from_name_with_version?(project, namespace, module_name, version)
        ModuleRepoInfo.new(matching_module[:module_branch])
      end
    end

    def self.get_common_module?(project, namespace, module_name, version)
      find_from_name_with_version?(project, namespace, module_name, version)
    end

    # opts can have keys
    #   :local_params
    #   :repo_name
    #   :service_instance
    #   :force_pull - Boolean (default false)
    #   :force_parse - Boolean (default false)
    def self.update_from_repo(common_module_type, project, commit_sha, opts = {})
      Update.update_class(common_module_type).update_from_repo(project, commit_sha, opts)
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

    def self.transform_from_raw_remote_module_info(raw_info)
      { remote_repo_url: raw_info[:remote_repo_url] }
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

    # TODO: DTK-2766: consider handling condition where service module at some version x requires component module
    #       at another version; in this case want to use the different versions of these modules.
    #       Need to figure out best version to use for combined; default is the service module version
    #       Alternative is to fix up modules that have different versions
    def self.intersect_versions(raw_service_info, raw_component_info)
      if raw_service_info
        if raw_component_info
          if raw_service_info[:latest_version] == raw_component_info[:latest_version]
            raw_service_info[:latest_version]
          else
            Aux.latest_version?(raw_service_info[:versions] && raw_component_info[:versions]) || 
              fail(ErrorUsage, "Mismatch between component info and service info versions")
          end
        else
          raw_service_info[:latest_version]
        end
      elsif raw_component_info
        raw_component_info[:latest_version]
      else
        fail ErrorUsage, "Unexpected that both raw_component_info and raw_component_info are nil"
      end
    end

  end
end
