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

        def initialize(existing_aug_mb, nested_module_info, service_instance, service_module_branch)
          @existing_aug_mb       = existing_aug_mb # existing augmented module branch
          @nested_module_info    = nested_module_info
          @service_instance      = service_instance
          @service_module_branch = service_module_branch
        end
        private :initialize

        # Processes changes to the nested module content and dsl 
        def self.process_nested_module_changes(diff_result, service_instance, service_module_branch, all_impacted_file_paths, opts = {})
          ndx_existing_aug_module_branches = service_instance.aug_component_module_branches(reload: true).inject({}) { |h, r| h.merge(r[:module_name] => r) }
          if nested_modules_info = impacted_nested_modules_info?(service_module_branch, all_impacted_file_paths)
            # Find existing aug_module_branches for service instance nested modules and for each one impacted 
            # create a service instance specfic branch if needed; ndx_existing_aug_module_branches is indexed by nested module name
            nested_modules_info.each do |nested_module_info|
              nested_module_name = nested_module_info.module_name
              unless existing_aug_mb = ndx_existing_aug_module_branches[nested_module_name]
                fail Error, "Unexpected that ndx_existing_aug_module_branches[#{nested_module_name}] is nil"
              end
              new(existing_aug_mb, nested_module_info, service_instance, service_module_branch).process(diff_result)
            end
          end

          delete_nested_module_directories?(ndx_existing_aug_module_branches, service_module_branch, opts)
        end

        def process(diff_result)
          aug_service_specific_mb = @service_instance.get_or_create_for_nested_module(nested_component_module, base_version)

          # Push changes to impacted component modules repo
          NestedModuleRepo.push_to_component_module(@service_module_branch, aug_service_specific_mb, @nested_module_info)
          # TODO: DTK-2708: until use dtk-dsl to parse nested module dsl; need to do push first since'
          # parsing looks at component module not the service isnatnce repo
          dsl_changed = false
          if impacted_dsl_files = @nested_module_info.restrict_to_dsl_files?
            DSL.process_nested_module_dsl_changes(diff_result, @service_instance, aug_service_specific_mb, impacted_dsl_files)
            dsl_changed = true
          end
          # Update the impacted component instancesm which includes updating the module_refs locks
          # This has to be done after all changes have been pushed to nested modules
          update_opts =  { meta_file_changed: dsl_changed, service_instance_module: true }
          AssemblyModule::Component.update_impacted_component_instances(assembly_instance, nested_component_module, aug_service_specific_mb, update_opts)
          # TODO: update diff_result to indicate module that was updated 
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
