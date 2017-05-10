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
      class Add < CommonDSL::Diff::Element::Add
        include Mixin

        def process(result, opts = {})
          assembly_instance    = service_instance.assembly_instance
          # TODO: DTK-3005: this does not handle link other than explicit link name; need to pass this into parse
          link_name            = relative_distinguished_name
          base_link_params     = ret_base_link_params(assembly_instance, qualified_key)
          dep_link_params      = component_link_value.dependency_link_params(assembly_instance)

          assembly_instance.add_component_link_from_link_params(base_link_params, dep_link_params, link_name: link_name)
          result.add_item_to_update(:assembly)
        end

        private

        def component_link_value 
          @component_link_valu ||= ComponentLink::Value.new(parse_object.value, parse_object.external_service_name?)
        end

      end
    end
  end
end
