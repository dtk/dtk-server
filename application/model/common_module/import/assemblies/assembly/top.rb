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
  class CommonModule::Import::Assemblies
    module Assembly
      module Top
        def self.db_update_hash(parsed_assembly, module_branch, module_name)
          assembly_name = parsed_assembly.req(:Name)
          {
            'display_name'     => assembly_name,
            'type'             => 'composite',
            'description'      => parsed_assembly.val(:Description),
            'module_branch_id' => module_branch.id,
            'version'          => module_branch.get_field?(:version),
            'component_type'   => ::DTK::Assembly.ret_component_type(module_name, assembly_name)
          }
        end
      end
    end
  end
end

