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

        def add_component_link!(result, assembly_instance, dep_link_params)
          link_name         = relative_distinguished_name
          base_link_params  = ret_base_link_params(assembly_instance, qualified_key)
          assembly_instance.add_component_link_from_link_params(base_link_params, dep_link_params, link_name: link_name)
          result.add_item_to_update(:assembly)
        end

        def delete_component_link!(result, assembly_instance)
          require 'debugger'
          Debugger.wait_connection = true
          Debugger.start_remote
          debugger
          port_links          = assembly_instance.get_augmented_port_links
          link_name           = relative_distinguished_name
          base_component_info = qualified_key.parent_component_info

          matching_port_links = port_links.select do |port_link| 
            port_link.display_name == link_name and 
              port_link[:input_component].display_name_print_form == base_component_info.component_name and
              (base_component_info.node_name.nil? or port_link[:input_node].display_name == base_component_info.node_name)
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

        def ret_base_link_params(assembly_instance, qualified_key)
          info = qualified_key.parent_component_info
          link_params_class::Base.new(assembly_instance, component_name: info.component_name, node_name: info.node_name)
        end

        def self.ret_base_link_params(assembly_instance, qualified_key)
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
