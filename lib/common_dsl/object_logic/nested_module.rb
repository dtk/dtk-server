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
  module CommonDSL
    module ObjectLogic
      class NestedModule < Generate::ContentInput::Hash
        require_relative('nested_module/component')

        def initialize(service_module_branch, aug_nested_module_branch)
          super()
          @service_module_branch    = service_module_branch
          @dsl_version              = service_module_branch.dsl_version
          @aug_nested_module_branch = aug_nested_module_branch
        end
        private :initialize

        def self.generate_content_input(service_module_branch, aug_nested_module_branch)
          new(service_module_branch, aug_nested_module_branch).generate_content_input!
        end

        def generate_content_input!
          dsl_input_hash      = ModuleDSL.get_dsl_file_input_hash(@aug_nested_module_branch.implementation)
          module_refs         = ModuleRefs.get_component_module_refs(@aug_nested_module_branch)

          set(:DSLVersion, @dsl_version)
#          set(:Name, assembly_instance.display_name)
          set(:DependentModules, Dependency.generate_content_input_from_module_refs(module_refs))
          set(:Components, Component.generate_content_input_from_hash(dsl_input_hash))
          self
        end
        
      end
    end
  end
end
