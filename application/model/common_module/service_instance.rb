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
      require_relative('service_instance/repo_info')

      # Returns CommonModule::ServiceInstance::RepoInfo
      # opts can have keys
      #   :add_nested_modules
      def self.create_service_instance_and_nested_modules(assembly_instance, opts = {})
        new(assembly_instance).create_service_instance_and_nested_modules(opts)
      end
      def create_service_instance_and_nested_modules(opts = {})
        base_service_module_branch = get_or_create_module_for_service_instance(opts.merge(delete_existing_branch: true))
        service_module_branch = CommonDSL::Generate::ServiceInstance.generate_dsl_and_push!(self, base_service_module_branch) 

        service_instance_repo_info = RepoInfo.new(service_module_branch)
        if opts[:add_nested_modules]
          self.aug_nested_base_module_branches.each do |aug_nested_base_module_branch|
            aug_nested_module_branch = process_nested_module(aug_nested_base_module_branch)
            service_instance_repo_info.add_nested_module_info!(aug_nested_module_branch)
          end
        end
        service_instance_repo_info
      end

      # Returns an augmented module branch pointing to module branch for nested mdoule
      # opts can have keys
      #   :donot_update_model
      #   :delete_existing_branch
      def get_or_create_for_nested_module(component_module, base_version, opts = {})
        create_opts = {
          donot_update_model: opts[:donot_update_model],
          delete_existing_branch: opts[:delete_existing_branch],
          base_version: base_version, 
          ret_augmented_module_branch: true
        }
        AssemblyModule::Component.new(self.assembly_instance).create_module_for_service_instance?(component_module, create_opts) 
      end

      def self.delete_from_model_and_repo(assembly_instance)
        if running_task = assembly_instance.most_recent_task_is_executing?
          fail ErrorUsage, "Task with id '#{running_task.id}' is already running. Please wait until the task is complete or cancel the task."
        end
        
        # TODO: Put in logic to check if theer are any nodes or components and raise error unless an option passed
        # If ther are nodes we want to destroy the nodes, i.e., terminate
        delete_opts = {
          destroy_nodes: true,
          uninstall: true
        }
        Assembly::Instance.delete(assembly_instance.id_handle, delete_opts)
      end

      def get_dsl_locations
        assembly_instance.get_dsl_locations
      end

      def get_repo_info
        module_repo_info = ModuleRepoInfo.new(get_service_instance_branch)
        {
          service: {
            name: self.assembly_instance.display_name_print_form,
            id: self.assembly_instance.id
          }
        }.merge(module_repo_info)
      end

      def aug_component_module_branches(opts = {})
        return reload_aug_component_module_branches if opts[:reload]
        @aug_dependent_module_branches ||= reload_aug_component_module_branches
      end

      protected

      def aug_nested_base_module_branches
        @aug_nested_base_module_branches || ret_aug_nested_base_module_branches
      end

      def service_module_name
        @service_module_name ||= self.service_module.display_name
      end

      def service_module_namespace
        @service_module_namespace ||= self.service_module[:namespace].display_name
      end

      private

      def ret_aug_nested_base_module_branches
        self.aug_component_module_branches.reject do |aug_module_branch|
          aug_module_branch[:module_name] == self.service_module_name and
            aug_module_branch[:namespace] == self.service_module_namespace
        end
      end

      def process_nested_module(aug_nested_base_module_branch)
        component_module = aug_nested_base_module_branch.component_module
        base_version     = aug_nested_base_module_branch.version
        # creating new branch, but no need to update the model
        get_or_create_opts = {
          donot_update_model: true,
          delete_existing_branch: true
        }
        aug_nested_module_branch = get_or_create_for_nested_module(component_module, base_version, get_or_create_opts)
        CommonDSL::NestedModuleRepo.update_repo_for_stage(aug_nested_module_branch)
        aug_nested_module_branch
      end
        
      def reload_aug_component_module_branches
        ModuleRefs::Lock.get_corresponding_aug_module_branches(assembly_instance, augment_with_component_modules: true)
      end

    end
  end
end
