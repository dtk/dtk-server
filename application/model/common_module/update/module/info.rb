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
  class CommonModule::Update::Module
    class Info < self
      require_relative('info/service')
      require_relative('info/component')

      attr_reader :module_name, :namespace_name, :version

      private

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      def initialize(project, common_module__local_params, common_module__repo, common_module__module_branch, parsed_common_module, opts = {})
        @project                      = project
        @module_name                  = common_module__local_params.module_name
        @namespace_name               = common_module__local_params.namespace
        @common_module__module_branch = common_module__module_branch
        @version                      = common_module__module_branch[:version]
        @local_params                 = self.class.create_local_params(module_type, @module_name, version: @version, namespace: @namespace_name)
        @parsed_common_module         = parsed_common_module
        @common_module__repo          = common_module__repo
        @module_class                 = self.class.get_class_from_module_type(module_type)
        @parse_needed                 = opts[:parse_needed]
        @diffs_summary                = opts[:diffs_summary]
      end

      attr_reader :project, :local_params, :parsed_common_module, :module_class, :common_module__repo, :common_module__module_branch
      def parse_needed?
        @parse_needed
      end

      def diffs_summary?
        @diffs_summary
      end

      # if module does not exist, create it
      # else if module branch does not exist, create it
      # else return module branch
      # opts can have keys:
      #   :create_implementation - Boolean (default: false)
      def create_module_branch_and_repo?(opts = {})
        if module_obj = module_class.find_from_name?(project.model_handle(module_type), namespace_name, module_name)
          namespace_obj = Namespace.find_by_name(project.model_handle(:namespace), namespace_name)
          if module_branch = module_class.get_workspace_module_branch(project, module_name, version, namespace_obj, no_error_if_does_not_exist: true)
            module_branch
          else
            repo = module_obj.get_repo
            module_branch = module_class.create_ws_module_and_branch_obj?(project, repo.id_handle, module_name, version, namespace_obj, return_module_branch: true)
            repo.merge!(branch_name: module_branch[:branch])
            RepoManager.add_branch_and_push?(module_branch[:branch], { empty: true }, module_branch)
            module_branch
          end
        else
          module_class.create_module(project, local_params, return_module_branch: true, create_implementation: opts[:create_implementation])
        end
      end

      # For module_refs processng
      # opts can have keys
      #   :omit_base_reference
      def update_component_module_refs(module_branch, parsed_dependent_modules, opts = {})
        component_module_refs = ModuleRefs.get_component_module_refs(module_branch)
        cmp_modules_with_namespaces = parsed_dependent_modules.map do |parsed_module_ref|
          parsed_module_name = parsed_module_ref.req(:ModuleName)
          # For legacy where dependencies can refer to themselves
          unless @module_name == parsed_module_name 
            cmp_modules_with_namespaces_hash(parsed_module_name, parsed_module_ref.req(:Namespace), parsed_module_ref.val(:ModuleVersion)) 
          end
        end.compact
        
        # add reference to oneself if not there and there is a corresponding component module ref 
        if opts[:omit_base_reference] and not base_module_in?(cmp_modules_with_namespaces)
          cmp_modules_with_namespaces << cmp_modules_with_namespaces_hash(module_name, namespace_name, version)
        end
        # The call 'component_module_refs.update_object_if_needed!' updates the object component_module_refs and returns true if changed
        # The call 'component_module_refs.update' updates the object model
          component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
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
