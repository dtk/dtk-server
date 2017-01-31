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
  class BaseModule < Model
    require_relative('base_module/update_module')
    require_relative('base_module/version_context_info')

    # TODO: look through r8_nested_require('module'..,) and see which ones should be under instead base_module
    require_relative('module/dsl')
    require_relative('module/node_module_dsl')
    require_relative('module/auto_import')

    require_relative('module/delete_mixin')

    include DeleteMixin
    extend ModuleClassMixin
    extend AutoImport
    include ModuleMixin
    include UpdateModule::Mixin
    extend UpdateModule::ClassMixin

    def get_associated_assembly_templates
      ndx_ret = {}
      get_objs(cols: [:assembly_templates]).each do |r|
        assembly_template = r[:assembly_template]
        ndx_ret[assembly_template[:id]] ||= Assembly::Template.create_as(assembly_template)
      end
      Assembly::Template.augment_with_namespaces!(ndx_ret.values)
    end

    # each of the module's component_templates associated with zero or more assembly template component references
    # component refs indexed by component template; plus augmented info for cmp refs; it has form
    # Component::Template:
    #   component_refs:
    #   - ComponentRef:
    #      node: Node
    #      assembly_template: Assembly::Template
    def get_associated_assembly_cmp_refs
      ndx_ret = {}
      get_objs(cols: [:assembly_templates]).each do |r|
        component_template = r[:component_template]
        pntr = ndx_ret[component_template[:id]] ||= component_template.merge(component_refs: [])
        pntr[:component_refs] << r[:component_ref].merge(r.hash_subset(:id, :display_name, :node, :assembly_template))
      end
      ndx_ret.values
    end

    def get_associated_component_instances
      ndx_ret = {}
      get_objs(cols: [:component_instances]).each do |r|
        cmp = r[:component]
        cmp[:namespace] = r[:namespace][:display_name] if r[:namespace]
        ndx_ret[cmp[:id]] ||= Component::Instance.create_subclass_object(cmp)
      end
     ndx_ret.values
    end

    def info_about(about, cmp_id = nil)
      # TODO: hack because cmp_id can be string 
      if cmp_id 
        cmp_id = (cmp_id.empty? ? nil : cmp_id.to_i)
      end

      case about.to_sym
      when :components
        get_objs(cols: [:components]).map do |r|
          cmp = r[:component]
          branch = r[:module_branch]
          unless branch.assembly_module_version?
            display_name = Component::Template.component_type_print_form(cmp[:display_name], Opts.new(no_module_name: true))
            { id: cmp[:id], display_name: display_name, version: branch.version_print_form }
          end
        end.compact.sort { |a, b| "#{a[:version]}-#{a[:display_name]}" <=> "#{b[:version]}-#{b[:display_name]}" }
      when :attributes
        rows = get_objs(cols: [:attributes])
        # if cmp_id given then only return thos matching this component id
        rows.delete_if { |r| !(r[:component][:id] == cmp_id) } if cmp_id
        # TODO: hack because cmp_id can be string 

        ret = [] 
        rows.each do |r|
          attr   = r[:attribute]
          branch = r[:module_branch]
          # skip if assembly branch attributes or hidden
          if attr[:hidden] or branch.assembly_module_version?
            next
          end
          el = { 
            id:           attr[:id], 
            display_name: attr.print_path(r[:component]), 
            value:        attr[:value_asserted], 
            version:      branch.version_print_form 
          }
          ret << el
        end
        return ret.sort { |a, b| a[:display_name] <=> b[:display_name] }
      when :instances
        results = get_objs(cols: [:component_module_instances_assemblies])
        # another query to get component instances that do not have assembly
        results += get_objs(cols: [:component_module_instances_node])

        results.map do |el|
          component_instance = el[:component_instance]
          display_name_parts = {
            node: el[:node][:display_name],
            component: Component::Instance.print_form(component_instance)
          }
          display_name = "#{display_name_parts[:node]}/#{display_name_parts[:component]}"
          if assembly = el[:assembly]
            assembly_name = assembly[:display_name]
            display_name_parts.merge!(assembly: assembly_name)
            display_name = "#{assembly_name}/#{display_name}"
          end
          {
            id: component_instance[:id],
            display_name: display_name,
            display_name_parts: display_name_parts,
            service_instance: display_name_parts[:assembly],
            node: display_name_parts[:node],
            component_instance: display_name_parts[:component],
            version: ModuleBranch.version_from_version_field(component_instance[:version])
          }
        end
      else
        fail Error.new("TODO: not implemented yet: processing of info_about(#{about})")
      end
    end

    def self.module_specific_type(config_agent_type)
      config_agent_type
    end

    def self.exists(project, namespace, module_name, version = nil)
      ret = {}

      if service_module_id = ServiceModule.module_exists(project, namespace, module_name, version)
        ret.merge!(service_module_id: service_module_id)
      elsif component_module_id = ComponentModule.module_exists(project, namespace, module_name, version)
        ret.merge!(component_module_id: component_module_id)
      end

      ret
    end

    def module_branches
      self.update_object!(:module_branches)
      self[:module_branch]
    end

    # raises exception if more repos found
    def get_repo
      repos = get_repos
      unless repos.size == 1
        fail Error.new('unexpected that number of matching repos is not equal to 1')
      end

      repos.first
    end

    def get_repos
      get_objs_helper(:repos, :repo, remove_dups: true)
    end

    def get_associated_target_instances
      get_objs_uniq(:target_instances)
    end

    def config_agent_type_default
      ConfigAgent::Type.default_symbol
    end

    private

    def publish_preprocess_raise_error?(module_branch_obj)
      # unless get_field?(:dsl_parsed)
      unless module_branch_obj.dsl_parsed?
        fail ErrorUsage.new('Unable to publish module that has parsing errors. Please fix errors and try to publish again.')
      end
    end
  end
end
