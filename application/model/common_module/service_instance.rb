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
  class CommonModule
    class ServiceInstance < AssemblyModule::Service
      # opts can have keys
      #   :add_nested_modules
      def self.create_service_instance_and_nested_modules(assembly_instance, opts = {})
        new(assembly_instance).create_service_instance_and_nested_modules(opts)
      end
      def create_service_instance_and_nested_modules(opts = {})
        service_module_branch = get_or_create_module_for_service_instance(opts.merge(delete_existing_branch: true))
        generate_dsl_opts = opts[:add_nested_modules] ? { aug_nested_module_branches: aug_nested_module_branches } : {}
        CommonDSL::Generate::ServiceInstance.generate_dsl(self, service_module_branch, generate_dsl_opts)
        ModuleRepoInfo.new(service_module_branch)
      end

      # opts can have keys:
      #   :base_version
      # Returns a ModuleBranch::Augmented object 
      def get_or_create_service_specific_aug_module_branch(component_module, opts = {})
        AssemblyModule::Component.new(assembly_instance).create_module_for_service_instance?(component_module, { ret_augmented_module_branch: true }.merge(opts))
      end
      
      def self.create_empty_module(project, local_params, opts = {})
        opts = opts.merge(return_module_branch: true)
        service_module_branch = create_module(project, local_params, opts)
        ModuleRepoInfo.new(service_module_branch)
      end

      # opts can have keys:
      #   :destroy_nodes
      def self.delete(assembly_instance, opts = {})
        Model.Transaction do
          Assembly::Instance.delete(assembly_instance.id_handle, destroy_nodes: opts[:destroy_nodes], delete_service_module_branch: true)
        end
      end

      def get_repo_info
        module_repo_info = ModuleRepoInfo.new(get_service_instance_branch)
        assembly_instance = self.assembly_instance
        {
          service: {
            name: assembly_instance.display_name_print_form,
            id: assembly_instance.id
          }
        }.merge(module_repo_info)
      end

      # opts can have keys
      #  :augment_with_component_modules (Boolean)
      def aug_nested_module_branches(opts = {})
        aug_dependent_module_branches = ModuleRefs::Lock.get_corresponding_aug_module_branches(assembly_instance, opts)
        # TODO: DTK-2707: add in entry for base module being staged if it has component module
      end
        
    end
  end
end
