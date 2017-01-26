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
      # ComponentInfo covers both a nested module and a common module
      class ComponentInfoModule < ContentInputHash
        require_relative('component_info_module/component_def')
 
        def initialize(type, module_branch, aug_component_module_branch)
          super()
          @type                        = type # type can be :common_module or :nested_module 
          @module_branch               = module_branch
          @aug_component_module_branch = aug_component_module_branch
        end
        private :initialize

        def self.generate_content_input(type, module_branch, aug_component_module_branch)
          new(type, module_branch, aug_component_module_branch).generate_content_input!
        end

        def generate_content_input!
          set(:DSLVersion, dsl_version)
          set(:Module, "#{module_namespace}/#{module_name}")
          set(:Version, module_version)
          set?(:DependentModules, dependent_modules?)
          set?(component_defs_key, component_defs?)
          self
        end

        private

        def component_defs_key
          case @type
          when :common_module then :ComponentDefs
          when :nested_module then :Components
          else fail Error "Unexpected type '#{@type}'"
          end
        end

        def dependent_modules?
          module_refs = ModuleRefs.get_component_module_refs(@aug_component_module_branch)
          ret = Dependency.generate_content_input_from_module_refs(module_refs)
          ret.empty? ? nil : ret
        end
        
        def component_defs?
          dsl_input_hash = ModuleDSL.get_dsl_file_input_hash(@aug_component_module_branch.implementation)
          ret = ComponentDef.generate_content_input_from_hash(dsl_input_hash)
          ret.empty? ? nil : ret
        end

        def dsl_version
          @module_branch.dsl_version
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
