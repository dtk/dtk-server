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
  class CommonDSL::ObjectLogic::Assembly
    class ComponentLink::Diff
      module Mixin
        private

        def ret_base_link_params(assembly_instance, qualified_key)
          info = qualified_key.parent_component_info
          link_params_class::Base.new(assembly_instance, component_name: info.component_name, node_name: info.node_name)
        end

        def link_params_class
          Assembly::Instance::ComponentLink::LinkParams
        end

      end
    end
  end
end
