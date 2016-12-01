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
      def create_or_update_from_parsed_common_module?
        if parsed_component_defs = parsed_common_module.val(:ComponentDefs)
          pp [:parsed_component_defs, parsed_component_defs]
          module_branch  = create_or_ret_module_branch

          CommonDSL::Parse.set_dsl_version!(module_branch, parsed_common_module)

          update_component_module_refs_from_parsed_common_module(module_branch)

          # TODO: use legacy parsing routines for component modules
        end
      end

      private

      def module_type
        :component_module
      end
      
    end
  end
end
