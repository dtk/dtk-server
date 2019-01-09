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
module DTK; module CommonDSL
  class Diff
    module ServiceInstance
      class NestedModule
        require_relative('nested_module/dsl')
        require_relative('nested_module/diff')
        require_relative('nested_module/attribute')
        
        def initialize(existing_aug_mb, service_instance, service_module_branch, project)
          @existing_aug_mb       = existing_aug_mb # existing augmented module branch
          @service_instance      = service_instance
          @service_module_branch = service_module_branch
          @project               = project
        end
        private :initialize

        def self.process_partial_nested_module_changes(service_instance)
          module_ref_shas     = Assembly::Instance::ModuleRefSha.get_for_base_and_nested_modules(service_instance.assembly_instance)
          aug_module_branches = DependentModule.get_aug_dependent_module_branches(service_instance.assembly_instance)

          module_ref_sha_branch_ids = module_ref_shas.map { |mr_sha| mr_sha[:module_branch_id] }
          matching_aug_module_branches = aug_module_branches.select { |dep| module_ref_sha_branch_ids.include?(dep[:id]) }

          matching_aug_module_branches.each do |module_ref_branch|
            module_ref_branch.pull_repo_changes_and_return_diffs_summary(nil, {}) do |repo_diffs_summary|
              module_ref_branch.update_current_sha_from_repo!
              new_sha = module_ref_branch.get_field(:current_sha)
              if  mod_ref_sha = module_ref_shas.find{ |mr_sha| mr_sha[:module_branch_id] == module_ref_branch[:id] }
                mod_ref_sha.update(sha: new_sha)
              end
            end
          end
        end

        def self.add_component(diff_result, project_id, service_instance, service_module_branch, module_name, component_name, opts={})
          ndx_existing_aug_module_branches = DependentModule.get_aug_dependent_module_branches(service_instance.assembly_instance)
          existing_aug_mb = ndx_existing_aug_module_branches.find{|mb| mb[:module_name].eql?(module_name) && mb[:version].eql?(service_instance.get_service_instance_branch[:version])}
          nested_module_info = {}
          impl = existing_aug_mb.get_implementation
          parse_opts = {
            dsl_created_info: dsl_created_info(component_name, module_name),
            donot_update_module_refs: true,
            use_new_snapshot: opts[:use_new_snapshot]
          }
          component_module = existing_aug_mb.get_module
          update_opts = { version: existing_aug_mb.get_ancestor_branch?.version }
          dsl_obj = ::DTK::ModuleDSL.parse_dsl(component_module, impl, parse_opts)
          dsl_obj.update_model_with_ref_integrity_check(update_opts)
          #::DTK::CommonDSL::Diff::ServiceInstance::NestedModule::Component::Diff::Add.process(project_id, existing_aug_mb, service_instance, dsl_obj)
        end
        
        def self.delete_component(diff_result, project_id, service_instance, service_module_branch, module_name, component_name, opts={})
          ndx_existing_aug_module_branches = DependentModule.get_aug_dependent_module_branches(service_instance.assembly_instance)
          existing_aug_mb = ndx_existing_aug_module_branches.find{|mb| mb[:module_name].eql?(module_name) && mb[:version].eql?(service_instance.get_service_instance_branch[:version])}
          nested_module_info = {}
          ::DTK::CommonDSL::Diff::ServiceInstance::NestedModule::Component::Diff::Delete.process(existing_aug_mb, service_instance, component_name)
        end

        def self.modify_component(diff_result, project_id, service_instance, service_module_branch, module_name, component_name, opts={})
          ndx_existing_aug_module_branches = DependentModule.get_aug_dependent_module_branches(service_instance.assembly_instance)
          existing_aug_mb = ndx_existing_aug_module_branches.find{|mb| mb[:module_name].eql?(module_name) && mb[:version].eql?(service_instance.get_service_instance_branch[:version])}
          nested_module_info = {}
          ::DTK::CommonDSL::Diff::ServiceInstance::NestedModule::Component::Diff::Modify.process(component, component_name, extra_fields) 
        end

        def self.add_attribute(diff_result, service_instance, service_module_branch, module_name, component_name, attribute_name, attribute_value)
          #get module branches
          ndx_existing_aug_module_branches = service_instance.aug_dependent_base_module_branches
          existing_aug_mb = ndx_existing_aug_module_branches.find{|mb| mb[:module_name].eql? module_name}
          nested_module_info = {}
          component = existing_aug_mb.component_module.get_associated_component_instances.find{|c| c.display_name.eql? component_name}
          extra_fields =  {
          is_port: true,
          hidden: false,
          data_type: 'json',
          external_ref: '{"type": "puppet_attribute"}'
          }
          ::DTK::CommonDSL::Diff::ServiceInstance::NestedModule::Attribute::Diff::Add.process(component, attribute_name, attribute_value, extra_fields)    
        end

        def self.delete_attribute(diff_result, service_instance, service_module_branch, module_name, component_name, attribute_name)
          ndx_existing_aug_module_branches = service_instance.aug_dependent_base_module_branches
          existing_aug_mb = ndx_existing_aug_module_branches.find{|mb| mb[:module_name].eql? module_name}
          nested_module_info = {}
          component = existing_aug_mb.component_module.get_associated_component_instances.find{|c| c.display_name.eql? component_name}
          #get attribute from name and component id
          attribute = service_instance.assembly_instance.get_attributes_all_levels.find { |f| f[:display_name]==attribute_name && f[:component_component_id]==component.id}
          ::DTK::CommonDSL::Diff::ServiceInstance::NestedModule::Attribute::Diff::Delete.process(attribute) 
        end

        def self.modify_attribute(diff_result, service_instance, service_module_branch, module_name, component_name, attribute_name, attribute_value)
          #get module branches
          ndx_existing_aug_module_branches = service_instance.aug_dependent_base_module_branches
          existing_aug_mb = ndx_existing_aug_module_branches.find{|mb| mb[:module_name].eql? module_name}
          nested_module_info = {}
          component = existing_aug_mb.component_module.get_associated_component_instances.find{|c| c.display_name.eql? component_name}
          extra_fields =  {
          is_port: true,
          hidden: false,
          data_type: 'json',
          external_ref: '{"type": "puppet_attribute"}'
          } 
          old_attribute = service_instance.assembly_instance.get_attributes_all_levels.find { |f| f[:display_name]==attribute_name && f[:component_component_id]==component.id}
          ::DTK::CommonDSL::Diff::ServiceInstance::NestedModule::Attribute::Diff::Modify.process(component, old_attribute, attribute_value, extra_fields)
        end

        # Processes changes to the nested module content and dsl 
        def self.process_nested_module_changes(diff_result, project, updated_nested_modules, commit_sha, service_instance, service_module_branch, all_impacted_file_paths, opts = {})
          if all_impacted_file_paths.include?('dtk.module.yaml')
            module_ref_shas = Assembly::Instance::ModuleRefSha.get_for_base_and_nested_modules(service_instance.assembly_instance)
            ndx_existing_aug_module_branches = []
            module_ref_shas.each do |sha|
              mbmh = service_instance.assembly_instance.model_handle.createMH(:module_branch)
              sp_hash = {
                cols: [:id, :display_name, :component_id, :component_module_info],
                filter: [:eq, :id, sha[:module_branch_id]]
              }
              ndx_existing_aug_module_branches << Model.get_obj(mbmh, sp_hash)
            end
            if existing_aug_mb = ndx_existing_aug_module_branches.compact.find{|mb| mb[:component_module][:display_name].eql?(service_module_branch.get_module[:display_name])}
              ModuleBranch::Augmented.augment_with_repos!([existing_aug_mb])
              new(existing_aug_mb, service_instance, service_module_branch, project).process(diff_result, nil, opts)
            end
          end
          ndx_existing_aug_module_branches= DependentModule.get_aug_dependent_module_branches(service_instance.assembly_instance)
          updated_nested_modules.each do |module_name, nm_commit_sha|
            existing_aug_mb = ndx_existing_aug_module_branches.find{|mb| mb[:module_name].eql?(module_name) && mb[:version].eql?(service_instance.get_service_instance_branch[:version])}
            new(existing_aug_mb, service_instance, service_module_branch, project).process(diff_result, nm_commit_sha, opts)
          end
        end

        def process(diff_result, commit_sha, opts)
          DSL.process_nested_module_dsl_changes(diff_result, @project, commit_sha,  @service_instance, @existing_aug_mb, opts)
          update_opts =  { meta_file_changed: true, service_instance_module: true }
          AssemblyModule::Component.update_impacted_component_instances(@service_instance.assembly_instance, @existing_aug_mb.get_module, @existing_aug_mb, update_opts)
        end

        private

        def self.delete_nested_module_directories?(ndx_existing_aug_module_branches, service_module_branch, opts = {})
          current_module_refs = opts[:current_module_refs] || []

          unless current_module_refs.empty?
            current_mr_names = current_module_refs.map { |cmr| cmr[:module_name] }
            new_mr_names     = ndx_existing_aug_module_branches.keys
            to_delete        = current_mr_names - new_mr_names

            to_delete.each do |mr|
              RepoManager.delete_directory?("modules/#{mr}", {push_changes: true}, service_module_branch)
            end
          end
        end

        # returns array of Parse::NestedModuleInfo objects or nil if none
        def self.impacted_nested_modules_info?(service_module_branch, all_impacted_file_paths)
          Parse::NestedModuleInfo.impacted_modules_info?(service_module_branch, all_impacted_file_paths)
        end
        
        def assembly_instance 
          @service_instance.assembly_instance
        end

        def base_version   
          @existing_aug_mb.version
        end

        def nested_component_module
          @existing_aug_mb.component_module
        end

      end
    end
  end
end; end
