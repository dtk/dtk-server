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
          #TODO: DTK-2766: see if need to add file objects to the implementation object; check if needed in service instance
          component_module_branch = create_module_branch_and_repo?(create_implementation: true)
          CommonDSL::Parse.set_dsl_version!(component_module_branch, parsed_common_module)
          @aug_component_module_branch = component_module_branch.augmented_module_branch.augment_with_component_module!

          sync_component_module_from_common_module
          # TODO: do we need this, which is in service info too 
          # update_component_module_refs_from_parsed_common_module(@aug_component_module_branch)
          update_component_info_in_model_from_dsl if parse_needed?
        end
      end

      private

      def module_type
        :component_module
      end

      def sync_component_module_from_common_module
        # TODO: DTK-2766: push_to_component_module is expensive; look at using diffs for selected copying
        # also look at whether faster to copy files rather than using git push
        common_module__module_branch.push_to_component_module(@aug_component_module_branch)
        # transform from common module dsl to component module dsl form 
        transform_component_module_repo_dsl_files
      end

      def transform_component_module_repo_dsl_files
        transform = Transform.new(parsed_common_module, self).compute_component_module_outputs!
        file_path__content_array = transform.file_path__content_array
        transform.input_paths.each { |path| RepoManager.delete_file?(path, {no_commit: true}, @aug_component_module_branch) }
        RepoManager.add_files(@aug_component_module_branch, file_path__content_array)
      end

      # TODO: DTK-2766: this uses the legagcy parsing routines in the dtk-server gem. Port over ti dtk-dsl parsing
      def update_component_info_in_model_from_dsl
        aug_mb = @aug_component_module_branch # alias
        impl = aug_mb.get_implementation
        response = aug_mb.component_module.parse_dsl_and_update_model(impl, aug_mb.id_handle, version, donot_update_module_refs: true)
        fail response if ModuleDSL::ParsingError.is_error?(response)
      end

    end
  end
end
