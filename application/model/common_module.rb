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
    require_relative('common_module/module_repo_info')
    # module_repo_info must be before service_instance
    require_relative('common_module/remote')
    require_relative('common_module/import') #TODO: should this be removed or have name changed after fully port to new client
    require_relative('common_module/update')
    require_relative('common_module/info')
    require_relative('common_module/service_instance')

    extend CommonModule::ClassMixin
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
        delete_existing_branch: true,  
        has_remote_repo: opts[:has_remote_repo]
      }
      # create_module also creates branch
      module_branch = create_module(project, local_params, create_module_opts)
      ModuleRepoInfo.new(module_branch)
    end

    def self.create_repo_from_component_info(project, common_module_local_params, opts = {})
      common_module_local    = common_module_local_params.create_local(project)
      component_module_local = common_module_local.merge(module_type: :component_module)
      Model.Transaction do
        common_module_repo  = create_repo(common_module_local, no_initial_commit: true, delete_if_exists: true)
        common_module_branch = create_module_and_branch_obj?(project, common_module_repo.id_handle, common_module_local, opts.merge(return_module_branch: true))
        Info::Component.populate_common_module_repo_from_component_info(component_module_local, common_module_branch, common_module_repo)
        ModuleRepoInfo.new(common_module_branch)
      end
    end

    # opts can have keys
    #  :remote_repo_base
    #  :detail_to_include
    def self.list_modules(project, opts = Opts.new)
      list(opts.merge(project_idh: project.id_handle, remove_assembly_branches: true))
    end

    def self.module_versions(project, namespace, module_name, opts = Opts.new)
      modules = list(opts.merge(project_idh: project.id_handle, remove_assembly_branches: true))
      matching_module = modules.find { |mod| mod[:display_name].eql?("#{namespace}:#{module_name}") }
      if versions = matching_module && matching_module[:versions]
        versions_array = versions.split(',')
        matching_module[:versions] = versions_array
      end
      matching_module
    end

    def self.list_assembly_templates(project)
      Info::Service.list_assembly_templates(project)
    end

    def self.get_module_dependencies(project, client_rsa_pub_key, remote_params)
      Info::Component.get_module_dependencies(project, client_rsa_pub_key, remote_params)
    end

    def self.get_local_module_dependencies(project, local_params)
      if matching_module = get_class_from_module_type(local_params.module_type).matching_module_with_module_branch?(project, local_params.namespace, local_params.module_name, local_params.version)
        Info::Component.get_local_module_dependencies(project, matching_module, local_params)
      else
        missing = { 'name' => local_params[:module_name], 'type' => local_params[:module_type], 'version' => local_params[:version], 'namespace' => local_params[:namespace] }
        {
          missing_module_components:[missing],
          dependency_warnings: [],
          required_modules: []
        }
        # fail ErrorUsage.new("DTK module '#{DTK::Common::PrettyPrintForm.module_ref(module_name, opts)}' does not exist!")
      end
    end

    def self.all_modules_with_versions_with_dependencies(project, response)
      modules = CommonModule.list_modules(project, Opts.new(:detail_to_include=>[:versions], return_raw: true))
      modules.each do |common_module|
        local_params = ModuleBranch::Location::LocalParams::Server.new(
          module_type: :common_module,
          module_name: common_module[:display_name],
          namespace: common_module[:namespace][:display_name],
          version: common_module[:module_branch][:version]
        )
        get_versions_with_dependencies(project, local_params, response)
      end
    end

    def self.get_versions_with_dependencies(project, local_params, response)
      if matching_module = get_class_from_module_type(local_params.module_type).matching_module_with_module_branch?(project, local_params.namespace, local_params.module_name, local_params.version)
        dependencies = matching_module.get_module_branch_from_local_params(local_params).get_module_refs
        response["#{local_params.namespace}/#{local_params.module_name}"] = [] unless response["#{local_params.namespace}/#{local_params.module_name}"]

        dep_hash = {
          'name' => local_params.version,
          'version' => local_params.version,
          'dependencies' => dependencies.map do |dep|
            {
              'namespace' => dep[:namespace_info],
              'module'    => dep[:display_name],
              'version'   => dep[:version_info]
            }
          end
        }

        unless response["#{local_params.namespace}/#{local_params.module_name}"].include?(dep_hash)
          response["#{local_params.namespace}/#{local_params.module_name}"] << dep_hash
        end

        dependencies.each do |dependency|
          unless response["#{dependency[:namespace_info]}/#{dependency[:display_name]}"]
            local_params = ModuleBranch::Location::LocalParams::Server.new(
              module_type: :common_module,
              module_name: dependency[:display_name],
              namespace: dependency[:namespace_info],
              version: dependency[:version_info]
            )
            get_versions_with_dependencies(project, local_params, response)
          end
        end
      end
    end

    def self.module_info_with_local_dependencies(project, module_list)
      Info::Component.module_info_with_local_dependencies(project, module_list)
    end

    # opts can have keys:
    #  :ret_remote_info
    def self.exists(project, namespace, module_name, version, opts = {})
      if matching_module = matching_module_with_module_branch?(project, namespace, module_name, version)
        ModuleRepoInfo.new(matching_module[:module_branch], ret_remote_info: opts[:ret_remote_info])
      end
    end

    def self.matching_module_branch?(project, namespace, module_name, version)
      if matching_module = matching_module_with_module_branch?(project, namespace, module_name, version)
        matching_module[:module_branch]
      end
    end

    def self.get_common_module?(project, namespace, module_name, version)
      matching_module_with_module_branch?(project, namespace, module_name, version)
    end

    def self.delete(project, namespace, module_name, version, opts = {})
      if version.is_a?(Array)
        version.each do |version|
          delete_version(project, namespace, module_name, version, opts)
        end
      else
        delete_version(project, namespace, module_name, version, opts)
      end
    end

    def self.delete_version(project, namespace, module_name, version, opts = {})
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
      when :service_module then Info::Service
      when :component_module then Info::Component
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
