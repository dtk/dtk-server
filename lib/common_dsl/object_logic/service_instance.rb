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
      class ServiceInstance < ContentInputHash
        def initialize(service_instance, module_branch)
          super()
          @service_instance = service_instance
          @module_branch    = module_branch
          @dsl_version      = module_branch.dsl_version
        end
        
        def generate_content_input!
          assembly_instance = @service_instance.respond_to?(:copy_as_assembly_instance) ? @service_instance.copy_as_assembly_instance : @service_instance.assembly_instance
          set(:DSLVersion, @dsl_version)
          set(:Name, assembly_instance.display_name)
          set(:DependentModules, Dependency.generate_content_input(assembly_instance))
          set(:Assembly, Assembly.generate_content_input(assembly_instance))
          self
        end

        def yaml_dsl_text
          Generate::FileGenerator.generate_yaml_text(:service_instance, self, @dsl_version)
        end
        
      end
    end
  end
end
