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
module DTK; class BaseModule
  module DeleteMixin
    def delete_object(opts = {})
      unless opts[:skip_validations]
        assembly_templates = get_associated_assembly_templates
        unless assembly_templates.empty?
          assembly_names = assembly_templates.map { |a| a.display_name_print_form(include_namespace: true) }
          fail ErrorUsage, "Cannot delete the component module because the assembly template(s) (#{assembly_names.join(',')}) reference it"
        end

        components = get_associated_component_instances
        raise_error_component_refs(components) unless components.empty?
      end

      impls = get_implementations
      delete_instances(impls.map(&:id_handle))
      repos = get_repos
      repos.each { |repo| RepoManager.delete_repo(repo) }
      delete_instances(repos.map(&:id_handle))
      delete_instance(id_handle)
      { module_name: module_name }
    end

    def delete_version?(version)
      delete_version(version, no_error_if_does_not_exist: true)
    end

    def delete_version(version, opts = {})
      ret = { module_name: module_name }
      unless module_branch = get_module_branch_matching_version(version)
        if opts[:no_error_if_does_not_exist]
          return ret
        else
          fail ErrorUsage, "Version '#{version}' for specified component module does not exist"
        end
      end

      # check if this module is dependency to other component/service module
      raise_error_if_dependency(module_branch, version)

      if implementation = module_branch.get_implementation?
        delete_instance(implementation.id_handle)
      end

      module_branch.delete_instance_and_repo_branch
      ret
    end

    def delete_version_or_module(version)
      module_branches = get_module_branches

      if module_branches.size > 1
        delete_version(version)
      else
        unless module_branch = get_module_branch_matching_version(version)
          if version
            fail ErrorUsage, "Version '#{version}' for specified component module does not exist!"
          else
            fail ErrorUsage, "Base version for specified component module does not exist. You have to specify version you want to delete!"
          end
        end
        # check if this module is dependency to other component/service module
        raise_error_if_dependency(module_branch, version)
        delete_object
      end
    end

    def delete_common_module_version_or_module(version, opts = {})
      unless get_module_branch_matching_version(version)
        if version
          fail ErrorUsage, "Version '#{version}' for specified component module does not exist!" 
        else
          # TODO: is this still applicable?
          fail ErrorUsage, "Base version for specified component module does not exist. You have to specify version you want to delete!"
        end
      end

      delete_associated_service_and_component_module_objects(self, version)

      if get_module_branches.size > 1
        delete_version(version)
      else
        delete_object(opts.merge(skip_validations: true))
      end
    end

    def delete_versions_except_base
      ret = { module_name: module_name }

      module_branches = get_module_branches
      module_branches.reject!{ |branch| branch[:version].nil? || branch[:version].eql?('master') }

      module_branches.each do |branch|
        delete_version(branch[:version])
      end

      ret
    end

    private

    def delete_associated_service_and_component_module_objects(common_module, version)
      delete_associated_params.each_pair do |module_type, module_class|
        model_handle = common_module.model_handle(module_type)
        if module_obj = module_class.find_from_name?(model_handle, common_module.module_namespace, common_module.module_name)
          if module_obj.get_module_branch_matching_version(version)
            if module_obj.get_module_branches.size > 1
              module_obj.delete_version(version, no_error_if_does_not_exist: true)
            else
              module_obj.delete_object(from_common_module: true)  
            end
          end
        end
      end
    end
    
    def delete_associated_params
      # Import that service_module is first; so it is deleted before component module
      @delete_associated_params ||= { service_module: CommonModule::ServiceInfo, component_module: CommonModule::ComponentInfo }
    end


    def raise_error_component_refs(components)
      ndx_assemblies = {}
      asssembly_ids =  components.map { |r| r[:assembly_id] }.compact
      unless asssembly_ids.empty?
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:oneof, :id, asssembly_ids]
        }
        ndx_assemblies = Assembly::Instance.get_objs(model_handle(:assembly_instance), sp_hash).inject({}) { |h, r| h.merge(r[:id] => r) }
      end
      refs = components.map do |r|
        cmp_ref = r.display_name_print_form(node_prefix: true, namespace_prefix: true)
        ref =
          if cmp_ref =~ /(^[^\/]+)\/([^\/]+$)/
            "Reference to '#{Regexp.last_match(2)}' on node '#{Regexp.last_match(1)}'"
          else
            "Reference to '#{cmp_ref}'"
          end
        if assembly = ndx_assemblies[r[:assembly_id]]
          ref << " in service instance '#{assembly.display_name_print_form}'"
        end
        ref
      end
      fail ErrorUsage, "Cannot delete the component module because the following:\n  #{refs.join("\n  ")}"
    end

    def raise_error_if_dependency(branch, version)
      components, services = ModuleRefs.get_module_refs_by_name_and_version(branch, module_namespace, module_name, version)

      # remove self from dependencies (component modules can have self set as dependency)
      components.reject!{ |cmp| cmp[:module_branch][:id] == branch[:id] }

      return if components.empty? && services.empty?


      refs = []
      unless components.empty?
        components.each do |cmp|
          version = cmp[:module_branch][:version]
          full_name = "#{cmp[:namespace][:display_name]}:#{cmp[:component_module][:display_name]}"
          full_name << "(#{version})" if version && !version.eql?('master')
          refs << "Reference to component module '#{full_name}'"
        end
      end

      unless services.empty?
        services.each do |srv|
          version = srv[:module_branch][:version]
          full_name = "#{srv[:namespace][:display_name]}:#{srv[:service_module][:display_name]}"
          full_name << "(#{version})" if version && !version.eql?('master')
          refs << "Reference to service module '#{full_name}'"
        end
      end

      fail ErrorUsage, "Cannot delete the component module because the following:\n  #{refs.join("\n  ")}"
    end
  end
end; end
