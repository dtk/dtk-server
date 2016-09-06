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
      # TODO: should create repo methods be in rescue blocks that cleanup if fails in the middle?

      def self.create_branch_and_generate_dsl(assembly_instance, opts = {})
        new(assembly_instance).create_branch_and_generate_dsl(opts)
      end

      def create_branch_and_generate_dsl(opts = {})
        # TODO: currently this creates a branch per service instance on the service module repo
        # that gets created when common module is created
        # Should we change to creating a repo per service instance?
        # Also this clones it from teh service module's base branch; is this right;
        # Some trade offs to consider:
        #  One advantage of service instance per branch is that we can merge between branches 
        # so can use this to for example merge tested changes in testing service instance to production service instance
        module_branch = get_or_create_service_instance_branch(opts)
        CommonDSL::Generate.generate_service_instance_dsl(self, module_branch)
        ModuleRepoInfo.new(module_branch)
      end

      def self.create_empty_module(project, local_params, opts = {})
        opts = opts.merge(return_module_branch: true)
        module_branch = create_module(project, local_params, opts)
        ModuleRepoInfo.new(module_branch)
      end

      def get_repo_info
        module_branch = get_or_create_service_instance_branch
        module_repo_info = ModuleRepoInfo.new(module_branch)
        assembly_instance = self.assembly_instance
        {
          service: {
            name: assembly_instance.display_name_print_form,
            id: assembly_instance.id
          }
        }.merge(module_repo_info)
      end

      # TODO: DTK-2445: to co-exist with assembly_module form should we choose a different branch name
      # The method get_or_create_assembly_branch uses the name that assembly_module does      
      def get_service_instance_branch
        get_assembly_branch
      end

      private

      def get_or_create_service_instance_branch(opts = {})
        get_or_create_assembly_branch(opts)
      end
    end
  end
end
