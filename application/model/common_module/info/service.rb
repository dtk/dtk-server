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
    module Info
      class Service < ServiceModule
        require_relative('service/remote')
        extend  CommonModule::ClassMixin
        include CommonModule::Mixin
        
        def self.info_type
          :service_info
        end
        
        # opts can have keys:
        #   :assembly_name
        #   :version      
        def assembly_template(opts = {})
          matching_templates = matching_assembly_templates(opts)
          if matching_templates.size == 1
            matching_templates.first
          else
            raise_error_when_no_unique_assembly_template(matching_templates, opts)
          end
        end
        
        def name_with_namespace
          get_field?(:ref)
        end
        
        def self.populate_common_module_repo_from_service_info(service_module_local, common_module_branch, common_module_repo)
          aug_service_module_branch = get_augmented_module_branch_from_local(service_module_local)
          common_module_branch.pull_from_service_module!(aug_service_module_branch)
          transform_from_service_info(common_module_branch, aug_service_module_branch)
          common_module_branch.push_changes_to_repo
        end

        def self.transform_from_service_info(common_module_branch, aug_service_module_branch, opts = {})
          RepoManager::Transaction.reset_on_error(common_module_branch) do
            transform_class.transform_from_service_info(:common_module, common_module_branch, aug_service_module_branch, common_module_dsl_file_path, opts)
            transform_class.commit_all_changes(common_module_branch, commit_msg: 'Loaded service info')
          end
        end
        
        def self.get_base_service_module(module_branch)
          copy_as(module_branch.get_module)
        end

        private
        
        
        # This causes all get_obj(s) class an instance methods to return Info::Service objects, rather than ServiceModule ones
        def self.get_objs(model_handle, sp_hash, opts = {})
          if model_handle[:model_name] == :service_module
            super.map { |service_module| copy_as(service_module) }
          else
            super
          end
        end

        def self.common_module_dsl_file_path
          common_module_file_type.canonical_path
        end

        def self.common_module_file_type
          @common_module_file_type ||= ::DTK::CommonDSL::FileType::CommonModule::DSLFile::Top
        end

        def self.transform_class
          @transform_class ||= CommonDSL::ServiceModuleRepoSync::Transform
        end
        
        # opts can have keys:
        #   :assembly_name
        #   :version
        def matching_assembly_templates(opts = {})
          template_version = opts[:version] || 'master'
          assembly_name = opts[:assembly_name]
          get_assembly_templates.select do |aug_template|
            template_version == aug_template[:version] and (assembly_name.nil? or assembly_name == aug_template.display_name)
          end
        end
        
      # opts can have keys:
        #   :assembly_name
        #   :version
        def raise_error_when_no_unique_assembly_template(matching_templates, opts = {})
          mod_ref = name_with_namespace
          mod_ref << "(#{opts[:version]})" if opts[:version]
          valid_names_list = matching_assembly_templates(version: opts[:version]).map(&:display_name).join(', ')
          if valid_names_list.empty?
            fail ErrorUsage, "The module '#{mod_ref}' has no assemblies"
          end
          if matching_templates.empty?
            if opts[:assembly_name]
              fail ErrorUsage, "The module '#{mod_ref}' has no assemblies that match '#{opts[:assembly_name]}'. Valid names are: #{valid_names_list}" 
            else
              # This should not be reached
              fail ErrorUsage, "The module '#{mod_ref}' has no assemblies"
            end
          else
            # only use version and not assembly name
            if opts[:assembly_name]
              fail ErrorUsage, "The assembly '#{opts[:assembly_name]}' does not exist in module '#{mod_ref}'. Valid asssembly template names are: #{valid_names_list}"
            else
              fail ErrorUsage, "The module '#{mod_ref}' has more than one assembly template. Please use 'dtk module stage' command with an assembly name. Legal names are: #{valid_names_list}"
              
            end
          end
        end

      end
    end
  end
end


