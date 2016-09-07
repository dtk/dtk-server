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
  class CommonModule
    module Import
      class ServiceModule < ::DTK::ServiceModule::AssemblyImport
        require_relative('service_module/assembly')
        include Assembly::Mixin

        def initialize(project, service_module, module_branch)
          module_refs   = ModuleRefs.get_component_module_refs(module_branch)
          @parent_class = service_module.class
          super(project.id_handle, module_branch, service_module, module_refs)
        end

        def put_needed_info_into_import_helper!(parsed_assemblies, opts = {})
          parsed_assemblies.each do |parsed_assembly|
            process_assembly!(parsed_assembly, opts)
          end
        end

        def import_into_model
          import
        end

      end
    end
  end
end
