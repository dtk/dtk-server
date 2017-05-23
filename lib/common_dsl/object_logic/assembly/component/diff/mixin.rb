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
    class ObjectLogic::Assembly::Component::Diff
      module Mixin
        private
        
        def component_name
          relative_distinguished_name
        end
        
        def component_title?
          component_type, title = ComponentTitle.parse_component_display_name(component_name)
          title
        end
        
        def parent_node
          Diff::QualifiedKey.parent_node?(qualified_key, assembly_instance) || assembly_instance.assembly_wide_node
        end

      end
    end
  end
end

