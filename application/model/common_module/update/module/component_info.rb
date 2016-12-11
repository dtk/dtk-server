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
    class ComponentInfo < self
      require_relative('component_info/transform')

      def create_or_update_from_parsed_common_module?
        if parsed_component_defs = parsed_common_module.val(:ComponentDefs)
          component_module_branch = create_module_branch_and_repo?
          CommonDSL::Parse.set_dsl_version!(component_module_branch, parsed_common_module)

          aug_component_module_branch = component_module_branch.augmented_module_branch
          common_module__module_branch.push_to_component_module(aug_component_module_branch)

          # transform from common module dsl to component module dsl form 
          transform_component_module_repo_dsl_files(aug_component_module_branch) 

          # TODO: do we need this update_component_module_refs_from_parsed_common_module(component_module_branch)
          
          # TODO: if any dsl changes invoke routine to update object module 
        end
      end

      private

      def module_type
        :component_module
      end


      def transform_component_module_repo_dsl_files(aug_component_module_branch) 
        transform = Transform.new(parsed_common_module, self).compute_component_module_outputs!
        file_path__content_array = transform.file_path__content_array

        transform.input_paths.each { |path| RepoManager.delete_file?(path, {no_commit: true}, aug_component_module_branch) }
        RepoManager.add_files(aug_component_module_branch, file_path__content_array)
      end

    end
  end
end
