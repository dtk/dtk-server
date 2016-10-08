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
  class CommonModule::ServiceInstance
    module NestedComponentModule
      module Mixin
        private

        end

      end
    end
  end
end

=begin
TODO: see if still can be levereged
    def add_nested_component_module(aug_base_module_branch)
          component_module = aug_base_module_branch[:component_module]
          component_module_banch = component_module.get_module_branch_matching_version(assembly_module_version) || create_nested_component_module(aug_base_module_branch)
          pp [:create_nested_component_module, component_module_banch]
          # CommonDSL::Generate.generate_service_instance_component_module_dsl(self, component_module_branch)
        end

        # returns new module_branch          
        def create_nested_component_module(aug_base_module_branch)
          base_repo = aug_base_module_branch[:repo]
          sha       = aug_base_module_branch[:current_sha]

          # create nested_component_repo_branch if needed
          new_version_repo, new_version_sha, new_branch_name =  aug_base_module_branch.create_new_branch_from_this_branch?(project, base_repo, assembly_module_version, sha: sha)
          local = 
          create_new_component_module_branch(aug_base_module_branch, new_version_sha, new_branch_name)
        end

        def create_new_component_module_branch(aug_base_module_branch, new_version_sha, new_branch_name)
          mb_create_hash = {
            display_name: new_branch_name,
            branch: new_branch_name,
            repo_id: aug_base_module_branch[:repo].id,
            is_workspace: true,
            type: 'component_module',
            version: assembly_module_version,
            ancestor_id: aug_base_module_branch.id,
            current_sha: new_version_sha,
            frozen: false # TODO: see if this is right
          }
        end

        def augment_with_component_modules!(module_branches)
          component_module_mh = assembly_instance.model_handle(:component_module)
          sp_hash = {
            cols: [:id, :group_id, :display_name],
            filter: [:oneof, :id, module_branches.map { |mb| mb[:component_id] }]
          }
          ndx_component_modules = Model.get_objs(component_module_mh, sp_hash).inject({}) do |h, component_module| 
            h.merge(component_module.id => component_module) 
          end
          module_branches.each do |module_branch|
            module_branch[:component_module] = ndx_component_modules[module_branch[:component_id]]
          end
          module_branches
        end

        def project
          @project ||= assembly_instance.get_target.get_project
        end
    
=end
