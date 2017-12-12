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

require 'ruby-debug'
module DTK
  class CommonModule::Update::Module
    class Info < self
      require_relative('info/service')
      require_relative('info/component')

      attr_reader :module_name, :namespace_name, :version

      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update  
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
        @initial_update               = opts[:initial_update]
      end

      # if module does not exist, create it
      # else if module branch does not exist, create it
      # else return module branch
      # opts can have keys:
      #   :create_implementation 
      # Returns module_branchobject
      def create_module_and_branch?(opts = {})
        debugger
        if module_obj = module_exists?
          module_branch_exists? || create_module_branch
        else
          create_module_and_branch(create_implementation: opts[:create_implementation])
        end
      end

      protected

      attr_reader :project, :local_params, :parsed_common_module, :module_class, :common_module__repo, :common_module__module_branch

      def parse_needed?
        @parse_needed
      end

      def diffs_summary?
        @diffs_summary
      end

      def initial_update?
        @initial_update
      end

      def namespace_obj 
        @namespace_obj = Namespace.find_by_name(self.project.model_handle(:namespace), self.namespace_name)
      end


      def parsed_dependent_modules
        @parsed_dependent_modules ||= parsed_nested_object(:DependentModules)
      end

      def parsed_assemblies
        @parsed_assemblies ||= parsed_nested_object(:Assemblies)
      end

      private

      # For module_refs processng
      # opts can have keys
      #   :omit_base_reference
      #   :add_recursive_dependencies
      def update_component_module_refs(module_branch,opts = {})
        component_module_refs       = ModuleRefs.get_component_module_refs(module_branch)
        cmp_modules_with_namespaces = ret_cmp_modules_with_namespaces(omit_base_reference: opts[:omit_base_reference])

        if opts[:add_recursive_dependencies]
          deps_of_deps = add_dependencies_of_dependencies(cmp_modules_with_namespaces)
          cmp_modules_with_namespaces.concat(deps_of_deps)
          cmp_modules_with_namespaces.uniq!
        end

        # The call 'component_module_refs.update_object_if_needed!' updates the object component_module_refs and returns true if changed
        # The call 'component_module_refs.update' updates the object model
        component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
      end

      def add_dependencies_of_dependencies(cmp_modules_with_namespaces)
        dependencies_of_dependencies = []
        existing_names = cmp_modules_with_namespaces.map{ |cmp| "#{cmp[:namespace_name]}/#{cmp[:display_name]}" }
        cmp_modules_with_namespaces.each do |cmp_module|
          if module_exists = ComponentModule.module_exists(self.project, cmp_module[:namespace_name], cmp_module[:display_name], cmp_module[:version_info], :return_module => true)
            if module_branch = module_exists[:module_branch]
              dep_module_refs = module_branch.get_module_refs
              dep_module_refs.each do |dep_module_ref|
                unless existing_names.include?("#{dep_module_ref[:namespace_info]}/#{dep_module_ref[:display_name]}")
                  dependencies_of_dependencies << { :namespace_name => dep_module_ref[:namespace_info], :display_name => dep_module_ref[:display_name], :version_info => dep_module_ref[:version_info] }
                end
              end
            end
          end
        end
        dependencies_of_dependencies
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
            hash[:display_name] == self.module_name and  
            hash[:namespace_name] == self.namespace_name and 
            hash[:version_info] == self.version
        end    
      end

      def module_exists?
        self.module_class.find_from_name?(project.model_handle(self.module_type), self.namespace_name, self.module_name)
      end

      def module_branch_exists?
        self.module_class.get_workspace_module_branch(self.project, self.module_name, self.version, self.namespace_obj, no_error_if_does_not_exist: true)
      end

      # opts can have keys:
      #   create_implementation
      def create_module_and_branch(opts = {})
        self.module_class.create_module(self.project, self.local_params, return_module_branch: true, create_implementation: opts[:create_implementation], donot_push_to_repo_manager: true)
      end

      def create_module_branch
        repo = module_obj.get_repo
        module_branch = self.module_class.create_ws_module_and_branch_obj?(self.project, repo.id_handle, self.module_name, self.version, namespace_obj, return_module_branch: true)
        repo.merge!(branch_name: module_branch[:branch])
        add_branch_opts = {
          empty: true,
          delete_existing_branch: self.initial_update?
        }
        # TODO: DTK-3366: removed
        # RepoManager.add_branch_and_push?(module_branch[:branch], add_branch_opts, module_branch)
        module_branch
      end      

      def parsed_nested_object(nested_object_key)
        self.parsed_common_module.val(nested_object_key)
      end

      # opts cna have keys
      #   :omit_base_reference
      def ret_cmp_modules_with_namespaces(opts = {})
        cmp_modules_with_namespaces = (self.parsed_dependent_modules || []).map do |parsed_module_ref|
          parsed_module_name = parsed_module_ref.req(:ModuleName)
          # For legacy where dependencies can refer to themselves
          unless self.module_name == parsed_module_name
            cmp_modules_with_namespaces_hash(parsed_module_name, parsed_module_ref.req(:Namespace), parsed_module_ref.val(:ModuleVersion))
          end
        end.compact
        
        # add reference to oneself if not there and there is a corresponding component module ref
        if opts[:omit_base_reference] and not base_module_in?(cmp_modules_with_namespaces)
          cmp_modules_with_namespaces << cmp_modules_with_namespaces_hash(self.module_name, self.namespace_name, self.version)
        end
        
        cmp_modules_with_namespaces
      end
    end
  end
end
