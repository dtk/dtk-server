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
    class Component < self
      require_relative('component/transform')

      # returns true if there is component info
      def create_or_update_from_parsed_common_module?
        if parsed_component_defs = parsed_common_module.val(:ComponentDefs)
          #TODO: DTK-2766: see if need to add file objects to the implementation object; check if needed in service instance
          component_module_branch = create_module_branch_and_repo?(create_implementation: true)
          CommonDSL::Parse.set_dsl_version!(component_module_branch, parsed_common_module)

          if parsed_dependent_modules = parsed_common_module.val(:DependentModules)
            update_component_module_refs(component_module_branch, parsed_dependent_modules)
          end

          @aug_component_module_branch = component_module_branch.augmented_module_branch.augment_with_component_module!

          # TODO: DTK-2766: update_component_info_in_model_from_dsl is very slow do to the underlying legacy
          # method to parse; First way to tackle this is to only call update_component_info_in_model_from_dsl if the component info
          # part is updated. We wil leveref the diff reasoning analogous that fro service insatnces lib/common_dsl/diff/service_instance/dsl.rb
          # add do coarse parsing. Later we will do away with legacy methods and do fine grain diff prasing for component updates
          # TODO: Might have to get that to work we wil also need to replace sync_component_module_from_common_module mechanism from pushing to bare repo
          # to copying files that are in @diffs_summary
          sync_component_module_from_common_module
          if parse_needed?
            PerformanceService.start('update_component_info_in_model_from_dsl')
            update_component_info_in_model_from_dsl(parsed_dependent_modules)
            PerformanceService.end_measurement('update_component_info_in_model_from_dsl')
          end
          true
        end
      end

      private

      def module_type
        :component_module
      end

      def sync_component_module_from_common_module
        common_module__module_branch.push_to_component_module(@aug_component_module_branch)
        # transform from common module dsl to component module dsl form 
        transform_component_module_repo_dsl_files
      end

      def transform_component_module_repo_dsl_files
        transform = Transform.new(parsed_common_module, self).compute_component_module_outputs!
        file_path__content_array = transform.file_path__content_array
        transform.input_paths.each { |path| RepoManager.delete_file?(path, {no_commit: true}, @aug_component_module_branch) }
        RepoManager.add_files(@aug_component_module_branch, file_path__content_array)
        RepoManager.push_changes(@aug_component_module_branch)
      end

      # TODO: DTK-2766: this uses the legacy parsing routines in the dtk-server gem. Port over to dtk-dsl parsing
      def update_component_info_in_model_from_dsl(parsed_dependent_modules)
        aug_mb = @aug_component_module_branch # alias
        # TODO: for migration purposes needed the  Implementation.create? method. This shoudl be done during initial create
        impl = aug_mb.get_implementation? || Implementation.create?(project, local_params, aug_mb.repo)
        parse_opts = {
          donot_update_module_refs: true
        }
        if parsed_dependent_modules
          parse_opts.merge!(dependent_modules: parsed_dependent_modules.map { |dependent_module| dependent_module.req(:ModuleName) })
        end
        response = aug_mb.component_module.parse_dsl_and_update_model(impl, aug_mb.id_handle, version, parse_opts)
        fail response if ModuleDSL::ParsingError.is_error?(response)
      end

      def dependent_modules

      end


    end
  end
end
