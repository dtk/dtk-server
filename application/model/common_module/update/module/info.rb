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
      # opts can have keys:
      #   :parse_needed
      #   :diffs_summary
      #   :initial_update  
      def initialize(parent, opts = {})
        common_module__module_branch  = parent.module_branch
        @parent                       = parent
        @project                      = parent.project
        @module_name                  = parent.local_params.module_name
        @namespace_name               = parent.local_params.namespace
        @common_module__module_branch = common_module__module_branch
        @version                      = common_module__module_branch[:version]
        @local_params                 = self.class.create_local_params(module_type, @module_name, version: @version, namespace: @namespace_name)
        @local                        = @local_params.create_local(@project)
        @parsed_common_module         = parent.parsed_common_module
        @common_module__repo          = parent.repo
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
        if module_obj = module_exists?
          module_branch_exists? || create_module_branch(module_obj)
        else
          create_module_and_branch(create_implementation: opts[:create_implementation])
        end
      end

      protected

      attr_reader :parent, :project, :local_params, :local, :parsed_common_module, :module_class, :common_module__repo, :common_module__module_branch

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
        @parsed_dependent_modules ||= self.parent.parsed_dependent_modules
      end

      def parsed_assemblies
        @parsed_assemblies ||= parsed_nested_object(:Assemblies)
      end

      private
      
      def module_exists?
        self.module_class.find_from_name?(project.model_handle(self.module_type), self.namespace_name, self.module_name)
      end

      def module_branch_exists?
        self.module_class.get_module_branch_from_local(self.local, no_error_if_does_not_exist: true)
      end

      # opts can have keys:
      #   create_implementation
      def create_module_and_branch(opts = {})
        self.module_class.create_module(self.project, self.local_params, return_module_branch: true, create_implementation: opts[:create_implementation], donot_push_to_repo_manager: true)
      end

      def create_module_branch(module_obj)
        repo = module_obj.get_repo
        module_branch = self.module_class.create_ws_module_and_branch_obj?(self.project, repo.id_handle, self.module_name, self.version, namespace_obj, return_module_branch: true)
        repo.merge!(branch_name: module_branch[:branch])
        module_branch
      end      

      def parsed_nested_object(nested_object_key)
        self.parsed_common_module.val(nested_object_key)
      end

    end
  end
end
