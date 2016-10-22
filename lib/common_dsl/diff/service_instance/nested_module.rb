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
      module NestedModule
        def self.process_nested_modules?(diff_result, service_instance, service_module_branch, impacted_files)
          if nested_modules_info = impacted_nested_modules_info?(impacted_files)
            process_nested_modules(diff_result, nested_modules_info, service_instance, service_module_branch)
          end
        end

        private

        def self.impacted_nested_modules_info?(impacted_files)
          Parse::NestedModule.matching_files_array(impacted_files)
        end

        def self.process_nested_modules(diff_result, nested_modules_info, service_instance, service_module_branch)
          # Find existing aug_module_branches for service instance nested modules and for each one impacted create a service isnatnce specfic branch
          # if needed
          ndx_existing_aug_module_branches = service_instance.aug_nested_module_branches(augment_with_component_modules: true).inject({}) { |h, r| h.merge(r[:module_name] => r) }
          assembly_instance = service_instance.assembly_instance

          nested_modules_info.each do |nested_module_info|
            module_name = nested_module_info.module_name
            unless existing_aug_mb = ndx_existing_aug_module_branches[module_name]
              fail Error, "Unexpected that ndx_existing_aug_module_branches[#{module_name}] is nil"
            end
            base_version     = existing_aug_mb.version
            component_module = existing_aug_mb.component_module

            # Create if needed the objects for a service instance specific modules
            aug_nested_module_branch = service_instance.get_or_create_service_specific_module_objects(component_module, base_version:  base_version)
            # TODO: process component_module_dsl_info if dsl file impacted

            # Push changes to impacted nested modules repos
            subtree_prefix = FileType::ServiceInstance::NestedModule.new(module_name: nested_module_info.module_name).base_dir
            service_module_branch.push_subtree_to_nested_module(subtree_prefix, aug_nested_module_branch)

            # Update the module_refs lock and the impacted component instances
            # This has to be done after all changes have been pushed to nested modules

            # TODO: check why we need to do ModuleRefs::Lock before AssemblyModule::Component here
            # while finalize edit does it in opposite order
            ModuleRefs::Lock.create_or_update(assembly_instance)
            AssemblyModule::Component.update_impacted_component_instances(assembly_instance, component_module, aug_nested_module_branch, donot_update_module_refs_lock: true)

           # TODO: update diff_result to indicate module taht was updated 
          end
        end

      end
    end
  end
end; end
