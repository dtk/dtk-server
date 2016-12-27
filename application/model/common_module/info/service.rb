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
        
        def self.update_assemblies_from_parsed_common_module(project, module_branch, parsed_assemblies, module_local_params)
          module_branch.set_dsl_parsed!(false)
          base_service_module = get_base_service_module(module_branch)
          import_helper = Import::ServiceModule.new(project, base_service_module, module_branch)
          import_helper.put_needed_info_into_import_helper!(parsed_assemblies, module_local_params)
          import_helper.import_into_model
          module_branch.set_dsl_parsed!(true)
        end
        
        private
        
        def self.get_base_service_module(module_branch)
          copy_as(module_branch.get_module)
        end
        
        # This causes all get_obj(s) class an instance methods to return Info::Service objects, rather than ServiceModule ones
        def self.get_objs(model_handle, sp_hash, opts = {})
          if model_handle[:model_name] == :service_module
            super.map { |service_module| copy_as(service_module) }
          else
            super
          end
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


