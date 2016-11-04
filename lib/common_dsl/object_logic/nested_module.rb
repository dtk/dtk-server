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
      class NestedModule < ContentInputHash
        require_relative('nested_module/component')

        def initialize(service_module_branch, aug_component_module_branch)
          super()
          @service_module_branch       = service_module_branch
          @aug_component_module_branch = aug_component_module_branch
        end
        private :initialize

        def self.generate_content_input(service_module_branch, aug_component_module_branch)
          new(service_module_branch, aug_component_module_branch).generate_content_input!
        end

        def generate_content_input!
          set(:DSLVersion, dsl_version)
          set(:Module, "#{module_namespace}/#{module_name}")
          set(:Version, module_version)
          set?(:DependentModules, dependent_modules?)
          set?(:Components, components?)
          self
        end

        private

        def dependent_modules?
          module_refs = ModuleRefs.get_component_module_refs(@aug_component_module_branch)
          ret = Dependency.generate_content_input_from_module_refs(module_refs)
          ret.empty? ? nil : ret
        end
        
        def components?
          dsl_input_hash = ModuleDSL.get_dsl_file_input_hash(@aug_component_module_branch.implementation)
          ret = Component.generate_content_input_from_hash(dsl_input_hash)
          ret.empty? ? nil : ret
        end

        def dsl_version
          @service_module_branch.dsl_version
        end

        def module_namespace
          @aug_component_module_branch.namespace
        end

        def module_name
          @aug_component_module_branch.component_module_name
        end

        def module_version
          @aug_component_module_branch.version
        end

      end
    end
  end
end
