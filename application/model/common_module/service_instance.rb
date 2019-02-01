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

      # opts can have keys
      #   :add_nested_modules
      #   :delete_existing_branch
      #   :version
      def initialize(assembly_instance, opts = {})
        super(assembly_instance)
        @base_version       = opts[:version]
        @base_module_branch = get_or_create_module_for_service_instance(delete_existing_branch: opts[:delete_existing_branch], version: opts[:version])
        @add_nested_modules = opts[:add_nested_modules]
      end

      attr_reader :base_module_branch

      # Returns CommonModule::ServiceInstance::RepoInfo
      # opts can have keys
      #   :add_nested_modules
      #   :version
      def self.create_service_instance_and_nested_modules(assembly_instance, opts = {})
        create_opts = {
          add_nested_modules: opts[:add_nested_modules], 
          delete_existing_branch: true,
          version: opts[:version]
        }
        new(assembly_instance, create_opts).create_service_instance_and_nested_modules
      end
      def create_service_instance_and_nested_modules
        process_base_module
        service_instance_repo_info = RepoInfo.new(self.base_module_branch)
        if self.add_nested_modules?
          self.aug_dependent_base_module_branches.each do |aug_base_module_branch|
            aug_nested_module_branch = process_nested_module(aug_base_module_branch)
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
          ret_augmented_module_branch: true,
          integer_version: opts[:integer_version]
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

      def get_base_module_repo_info
        module_repo_info = ModuleRepoInfo.new(self.base_module_branch)
        {
          service: {
            name: self.assembly_instance.display_name_print_form,
            id: self.assembly_instance.id
          }
        }.merge(module_repo_info)
      end

      def get_base_and_nested_module_repo_info
        service_instance_repo_info = RepoInfo.new(self.base_module_branch)

        self.aug_dependent_base_module_branches.each do |aug_base_module_branch|
          aug_nested_module_branch = get_nested_module_info(aug_base_module_branch)
          service_instance_repo_info.add_nested_module_info!(aug_nested_module_branch)
        end

        {
          service: {
            name: self.assembly_instance.display_name_print_form,
            id: self.assembly_instance.id
          }
        }.merge(service_instance_repo_info)
      end

      def get_dsl_locations
        self.assembly_instance.get_dsl_locations
      end

      def aug_dependent_base_module_branches
        @aug_dependent_base_module_branches ||= DependentModule.get_aug_base_module_branches(self.assembly_instance)
      end
      # TODO: scoped under protected so need to add public
      public :aug_dependent_base_module_branches

      protected

      attr_reader :base_version

      def add_nested_modules?
        @add_nested_modules
      end

      def service_module_name
        @service_module_name ||= self.service_module.display_name
      end
      
      def service_module_namespace
        @service_module_namespace ||= self.service_module[:namespace].display_name
      end

      private

      def process_base_module
        add_base_component_module_as_dependency(self.base_module_branch.augmented_module_branch)
        add_to_base_module_branch__dsl_file
        add_to_base_module_branch__gitignore
        RepoManager.push_changes(self.base_module_branch)
        self.base_module_branch.update_current_sha_from_repo! # updates object model to indicate sha read in
        Assembly::Instance::ModuleRefSha.create_for_base_module(self.assembly_instance, self.base_module_branch.augmented_module_branch)
      end
      
      def add_base_component_module_as_dependency(base_common_module_branch)
        common_module = base_common_module_branch.get_module
        base_version  = base_common_module_branch.get_ancestor_branch?[:version]
        project = ::DTK::Project.get_all(self.assembly_instance.model_handle(:project)).first
        if component_module = ComponentModule.module_exists(project, common_module.module_namespace, common_module.module_name, base_version, return_module: true)
          get_or_create_opts = {
            donot_update_model: false,
            delete_existing_branch: true,
            integer_version: 5
          }
          aug_nested_module_branch = get_or_create_for_nested_module(component_module, base_version, get_or_create_opts)

          add_components_from_new_templates(aug_nested_module_branch)

          Assembly::Instance::ModuleRefSha.create_for_nested_module(self.assembly_instance, aug_nested_module_branch)
        end
      end

      def add_to_base_module_branch__dsl_file
        CommonDSL::Generate::ServiceInstance.add_service_dsl_files(self, self.base_module_branch)
      end

      def add_to_base_module_branch__gitignore
        file_path__content_array = [ {path: '.gitignore', content: gitignore_content << ".task_id_*\n" }]
        CommonDSL::Generate::DirectoryGenerator.add_files(self.base_module_branch, file_path__content_array, donot_push_changes: true)
      end

      def process_nested_module(aug_nested_base_module_branch)
        component_module = aug_nested_base_module_branch.component_module
        base_version     = aug_nested_base_module_branch.version
        # creating new branch, but no need to update the model
        get_or_create_opts = {
          donot_update_model: false,
          delete_existing_branch: true,
          integer_version: 5
        }
        aug_nested_module_branch = get_or_create_for_nested_module(component_module, base_version, get_or_create_opts)
        CommonDSL::NestedModuleRepo.update_repo_for_stage(aug_nested_module_branch)
        Assembly::Instance::ModuleRefSha.create_for_nested_module(self.assembly_instance, aug_nested_module_branch)
        aug_nested_module_branch

        add_components_from_new_templates(aug_nested_module_branch)

        aug_nested_module_branch
      end

      def get_nested_module_info(aug_nested_base_module_branch)
        component_module = aug_nested_base_module_branch.component_module
        base_version     = aug_nested_base_module_branch.version

        get_or_create_opts = {
          donot_update_model: true,
          delete_existing_branch: false
        }
        get_or_create_for_nested_module(component_module, base_version, get_or_create_opts)
      end

      def gitignore_content
        CommonDSL::DirectoryType::ServiceInstance::NestedModule.possible_paths.inject('') do |s, possible_module_dir|
          # only put in git ignore if possible_module_dir is not part of base module
          directory_exists_in_module?(possible_module_dir)  ? s : s + "#{possible_module_dir.gsub('/','')}/\n"
        end
      end

      def directory_exists_in_module?(dir)
        RepoManager.file_exists?(dir, self.base_module_branch) 
      end

      def existing_component_instances
        return @existing_cmp_instances if @existing_cmp_instances

        @existing_cmp_instances = nil
        nodes = self.assembly_instance.get_nodes

        nodes.each do |node|
          @existing_cmp_instances = node.get_components(cols: [:id, :group_id, :display_name, :component_type, :assembly_id, :component_module])
        end

        @existing_cmp_instances
      end

      def add_components_from_new_templates(aug_nested_module_branch)
        project        = ::DTK::Project.get_all(self.assembly_instance.model_handle(:project)).first
        implementation = aug_nested_module_branch.get_implementation
        templates      = aug_nested_module_branch.get_component_templates

        existing_component_instances.each do |existing_cmp_instance|
          if existing_cmp_instance[:component_module][:id] == aug_nested_module_branch.component_module[:id]
            cmp_template_candidate = templates.find{ |template| template[:component_type] == existing_cmp_instance[:component_type] }
            component_template = cmp_template_candidate.id_handle.create_object(model_name: :component_template_augmented).merge(cmp_template_candidate)
            component_template_node = existing_cmp_instance.get_node

            title = nil
            if title_attr = Component::Template.get_title_attributes([existing_cmp_instance.id_handle]).first
              title_attr.update_object!(:value_asserted, :value_derived)
              title = title_attr[:value_asserted] || title_attr[:value_derived]
            end

            # delete component instances created during clone_into since they are tied to component templates from component modules
            Model.delete_instance(existing_cmp_instance.id_handle)

            assembly_instance.add_component(component_template_node.id_handle, component_template, self, component_title: title, do_not_update_workflow: true)
          end
        end
      end

    end
  end
end
