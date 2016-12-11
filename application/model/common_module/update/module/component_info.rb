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

          # push subtree to component module
          prefix = ''
          aug_component_module_branch = component_module_branch.augmented_module_branch
          # common_module__module_branch.push_subtree_to_component_module(prefix, aug_component_module_branch) # opts = {})

          # TODO: do we need this update_component_module_refs_from_parsed_common_module(component_module_branch)

          # compute the component module dsl files
          transform = Transform.new(parsed_common_module, self).compute_component_module_outputs!
          transform.output_path_text_pairs do |path, text|
            pp '--------------------------------------'
            pp path
            STDOUT << text
            pp '--------------------------------------'
          end
          # TODO: do a push subtree from common_module__repo_local_dir and use transform_to logic
        end
      end

      private

      def module_type
        :component_module
      end

      # used when do a push subtree
      def common_module__repo_local_dir
        @common_module__repo_local_dir ||= common_module__repo.get_field?(:local_dir)
      end

    end
  end
end
