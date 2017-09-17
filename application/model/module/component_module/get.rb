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
  class ComponentModule
    module Get
      module Mixin
        def get_matching_component_template?(component_name)
          component_type = Get.component_type(self, component_name)
          matches = get_component_templates.select { |component| component[:component_type] == component_type }
          fail Error "Unexpected that matches.size > 1" if matches.size > 1
          matches.first
        end
        
        def get_component_templates
          module_branch = self[:module_branch] || fail("Unexpected that self[:module_branch] is nil")
          get_objs(cols: [:components]).select { |row| row[:module_branch].id == module_branch.id }.map do |row|
            Component::Template.create_from_component(row[:component])
          end
        end
      end

      def self.component_type(component_module, component_name)
        Component.component_type_from_module_and_component(component_module.display_name, component_name)
      end

    end
  end
end
