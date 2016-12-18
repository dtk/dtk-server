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
  class CommonModule::Update::Module::Info
    class Service < self
      
      def initialize(*args)
        service_instance_opts = args.pop
        super(*args)
        @component_info_exists = service_instance_opts[:component_info_exists]
      end

      # returns true if there is service info
      def create_or_update_from_parsed_common_module?
        if parsed_assemblies = parsed_common_module.val(:Assemblies)
          service_module_branch = create_module_branch_and_repo?
          CommonDSL::Parse.set_dsl_version!(service_module_branch, parsed_common_module)
          update_component_module_refs_from_parsed_common_module(service_module_branch)
          CommonModule::ServiceInfo.update_assemblies_from_parsed_common_module(project, service_module_branch, parsed_assemblies, version)
          true
        end
      end

      private

      def module_type
        :service_module
      end

      # For module_refs processng
      def update_component_module_refs_from_parsed_common_module(service_module_branch)
        if dependent_modules = parsed_common_module.val(:DependentModules)
          component_module_refs = ModuleRefs.get_component_module_refs(service_module_branch)

          cmp_modules_with_namespaces = dependent_modules.map do |parsed_module_ref|
            cmp_modules_with_namespaces_hash(parsed_module_ref.req(:ModuleName), parsed_module_ref.req(:Namespace), parsed_module_ref.val(:ModuleVersion)) 
          end

          # add reference to oneself if not there and there is a corresponding component module ref 
          if @component_info_exists and not base_module_in?(cmp_modules_with_namespaces)
            cmp_modules_with_namespaces << cmp_modules_with_namespaces_hash(module_name, namespace_name, version)
          end
          # The call 'component_module_refs.update_object_if_needed!' updates the object component_module_refs and returns true if changed
          # The call 'component_module_refs.update' updates the object model
          component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
        end
      end

      def cmp_modules_with_namespaces_hash(module_name_input, namespace_name_input, version_input)
        { 
          display_name: module_name_input,
          namespace_name: namespace_name_input,
          version_info: version_input
        }
      end
      
      def base_module_in?(cmp_modules_with_namespaces)
        !!cmp_modules_with_namespaces.find do |hash|
            hash[:display_name] == module_name and  
            hash[:namespace_name] == namespace_name and 
            hash[:version_info] == version
        end    
      end

    end
  end
end
