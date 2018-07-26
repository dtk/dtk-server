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
  class Assembly::Instance
    module Add
      # for adding components
      module Component
        module Mixin
          # aug_cmp_template is a component template augmented with keys having objects
          #   :module_branch
          #   :component_module
          #   :namespace
          # opts can have keys
          #   :component_title
          def add_component(node_idh, aug_cmp_template, service_instance, opts = {})
            node = Component.check_node(self, node_idh)
            component = nil
            Transaction do
              component = node.add_component(aug_cmp_template, component_title: opts[:component_title], detail_to_include: [:component_dependencies]).create_object
              Component.update_workflow(self, node, component, component_title: opts[:component_title])

              LinkDef::AutoComplete.autocomplete_component_links(self, components: [component])

              # fail "TODO: DTK-3394: implement when add component"
              # need to update module_refs_lock to add new component which will be used below to pull nested component module into service instance if needed

              # ModuleRefs::Lock.create_or_update(self) - substitute with below
              get_or_create_opts = {
                donot_update_model: true,
                delete_existing_branch: true
              }
              aug_nested_module_branch = service_instance.get_or_create_for_nested_module(aug_cmp_template.component_module, aug_cmp_template.version, get_or_create_opts)
              ModuleRefSha.create_or_update_for_nested_module(service_instance.assembly_instance, aug_nested_module_branch)

              Component.pull_component_module_repos(aug_cmp_template, service_instance)
            end
            component.id_handle 
          end
        end

        def self.add_component(service_instance, component_ref, version, namespace, parent_node)
          assembly_instance     = service_instance.assembly_instance
          component_type, title = ComponentTitle.parse_component_display_name(component_ref)
          component_type        = ::DTK::Component.component_type_from_user_friendly_name(component_type)
          component_module_refs = assembly_instance.component_module_refs
          service_instance_base_branch = service_instance.base_module_branch
          service_repo_info     = CommonModule::ServiceInstance::RepoInfo.new(service_instance_base_branch)
          dependent_modules     = {}

          component_module_refs.module_refs_array.each { |dep| dependent_modules.merge!("#{dep[:namespace_info]}/#{dep[:display_name]}" => extract_version(dep[:version_info])) }

          aug_cmp_template = nil
          retries = 0
          add_nested_module = false

          begin
            aug_cmp_template = assembly_instance.find_matching_aug_component_template(component_type, component_module_refs, dependent_modules: dependent_modules)# dependent_modules: opts[:dependent_modules])
          rescue ErrorUsage => e
            fail ErrorUsage, "#{e.message}. Please provide 'namespace' and 'version' to add module to dependencies." if version.empty? || namespace.empty?

            if retries > 1
              fail e
            else
              new_dependency_info = { display_name: component_ref.split('::').first, namespace_name: namespace, version_info: version }
              add_dependency_to_module_refs(component_module_refs, new_dependency_info)
              add_nested_module = true
              retries += 1
              retry
            end
          end

          node =
            if parent_node
              assembly_instance.get_node?([:eq, :display_name, parent_node])
            else
              assembly_instance.assembly_wide_node
            end

          assembly_instance.add_component(node.id_handle, aug_cmp_template, service_instance, component_title: title)
          CommonDSL::Generate::ServiceInstance.generate_dsl_and_push!(service_instance, service_instance_base_branch)
          add_nested_module_info(service_repo_info, aug_cmp_template, service_instance) if add_nested_module

          service_repo_info
        end

        def self.check_node(assembly_instance, node_idh)
          # first check that node_idh is directly attached to the assembly instance
          # one reason it may not be is if its a node group member
          sp_hash = {
            cols: [:id, :display_name, :group_id, :ordered_component_ids],
            filter: [:and, [:eq, :id, node_idh.get_id], [:eq, :assembly_id, assembly_instance.id]]
          }

          unless node = Model.get_obj(assembly_instance.model_handle(:node), sp_hash)
            if node_group = assembly_instance.is_node_group_member?(node_idh)
              fail ErrorUsage, "Not implemented: adding a component to a node group member; a component can only be added to the node group (#{node_group[:display_name]}) itself"
            else
              fail ErrorIdInvalid.new(node_idh.get_id, :node)
            end
          end
          node
        end
        
        # opts can have keys
        #  :component_title
        #  :skip_if_not_found
        #  :splice_in_delete_action
        def self.update_workflow(action_instance, node, component, opts = {})
          update_opts = { skip_if_not_found: true }
          if opts[:splice_in_delete_action]
            cmp_instance = ::DTK::Component::Instance.create_from_component(component)
            action_def = cmp_instance.get_action_def?('delete')
            update_opts.merge!(:action_def => action_def)
          end
          if component_title = opts[:component_title]
            update_opts.merge!(:component_title => component_title)
          end
          Task::Template::ConfigComponents.update_when_added_component_or_action?(action_instance, node, component, update_opts)
        end

        def self.pull_component_module_repos(aug_cmp_template, service_instance)
          if service_instance
            # fail "TODO: DTK-3366: need to use different metod than service_instance.aug_component_module_branches"
            # existing_aug_module_branches = service_instance.aug_component_module_branches(reload: true).inject({}) { |h, r| h.merge(r[:module_name] => r) }
            existing_aug_module_branches = service_instance.aug_dependent_base_module_branches.inject({}) { |h, r| h.merge(r[:module_name] => r) }
            nested_module_name           = aug_cmp_template.component_module.module_name

            if matching_module_branch = existing_aug_module_branches[nested_module_name]
              matching_module_branches = [matching_module_branch]
              matching_module_branch.get_module_refs.each do |module_ref|
                if module_ref_branch = existing_aug_module_branches[module_ref[:display_name]]
                  matching_module_branches << module_ref_branch
                end
              end

              # fail Error, "TODO: DTK-3366; changed CommonDSL::NestedModuleRepo.pull_from_component_modules to update_repo_for_stage"
              # CommonDSL::NestedModuleRepo.pull_from_component_modules(service_instance.get_service_instance_branch, matching_module_branches)
              matching_module_branches.each do |aug_nested_module_branch|
                CommonDSL::NestedModuleRepo.update_repo_for_stage(aug_nested_module_branch)
              end
            end
          end
        end

        private

        def self.extract_version(version_obj)
          version_obj.is_a?(String) ? version_obj : version_obj.version_string
        end

        def self.add_dependency_to_module_refs(component_module_refs, new_dependency_info)
          modules_with_namespaces = component_module_refs.module_refs_array.map { |dep| { display_name: dep[:display_name], namespace_name: dep[:namespace_info], version_info: dep[:version_info].version_string } }
          modules_with_namespaces << new_dependency_info
          component_module_refs.update_module_refs_if_needed!(modules_with_namespaces)
        end

        def self.add_nested_module_info(service_repo_info, aug_cmp_template, service_instance)
          get_or_create_opts = {
            donot_update_model: true,
            delete_existing_branch: false
          }
          aug_nested_module_branch = service_instance.get_or_create_for_nested_module(aug_cmp_template.component_module, aug_cmp_template.version, get_or_create_opts)
          service_repo_info.add_nested_module_info!(aug_nested_module_branch)
        end

      end
    end
  end
end
