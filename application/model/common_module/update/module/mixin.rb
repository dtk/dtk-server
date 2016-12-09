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
    module Mixin
      attr_reader :module_name, :namespace_name, :version

      private

      attr_reader :project, :local_params, :parsed_common_module, :module_class, :common_module__repo
      def initialize(project, common_module__local_params, common_module__repo, module_version, parsed_common_module)
        @project              = project
        @module_name          = common_module__local_params.module_name
        @namespace_name       = common_module__local_params.namespace
        @version              = module_version
        @local_params         = self.class.create_local_params(module_type, @module_name, version: @version, namespace: @namespace_name)
        @parsed_common_module = parsed_common_module
        @common_module__repo  = common_module__repo
        @module_class         = self.class.get_class_from_module_type(module_type)
      end

      # if module does not exist, create it
      # else if module branch does not exist, create it
      # else return module branch
      def create_module_branch_and_repo?
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
          # TODO: think dont want to have return_module_branch: true so can pass repo craeted to componnet moulde processing
          # may be a bug once remove return_module_branch: true
          module_class.create_module(project, local_params, return_module_branch: true)
        end
      end

      def update_component_module_refs_from_parsed_common_module(module_branch)
        if dependent_modules = parsed_common_module.val(:DependentModules)
          component_module_refs = ModuleRefs.get_component_module_refs(module_branch)

          cmp_modules_with_namespaces = dependent_modules.map do |parsed_module_ref|
            { 
              display_name: parsed_module_ref.req(:ModuleName), 
              namespace_name: parsed_module_ref.req(:Namespace), 
              version_info: parsed_module_ref.val(:ModuleVersion) 
            }
          end
          
          component_module_refs.update if component_module_refs.update_object_if_needed!(cmp_modules_with_namespaces)
        end
      end

    end
  end
end
