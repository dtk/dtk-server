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
      class Delete < CommonDSL::Diff::Element::Delete
        def process(result, opts = {})
          assembly_instance   = service_instance.assembly_instance
          port_links          = assembly_instance.get_augmented_port_links
          base_component_name = qualified_key.parent_component_name
          link_name           = relative_distinguished_name

          
          matching_port_links = port_links.select do |port_link| 
            port_link.display_name == link_name and 
              port_link[:input_component].display_name_print_form == base_component_name
          end

          case matching_port_links.size
          when 1
            Assembly::Instance::ComponentLink.delete(matching_port_links.first.id_handle)
            result.add_item_to_update(:assembly)
          when 0
            result.add_error_msg("Unexpected that component link '#{link_name}' matches no links")
          else
            result.add_error_msg("Unexpected that component link '#{link_name}' matches multiple links")
          end
        end

      end
    end
  end
end

