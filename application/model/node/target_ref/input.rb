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
# For populating target refs from different input sources
module DTK; class Node
  class TargetRef
    class Input < Array
      r8_nested_require('input', 'inventory_data')
      r8_nested_require('input', 'base_nodes')

      def self.create_nodes_from_inventory_data(target, inventory_data)
        inventory_data.create_nodes_from_inventory_data(target)
      end

      #TODO: collapse with application/utility/library_nodes - node_info
      def self.child_objects(params = {})
        {
          'attribute' => {
            'host_addresses_ipv4' => {
              'required' => false,
              'read_only' => true,
              'is_port' => true,
              'cannot_change' => false,
              'data_type' => 'json',
              'value_derived' => [params['host_address']],
              'semantic_type_summary' => 'host_address_ipv4',
              'display_name' => 'host_addresses_ipv4',
              'dynamic' => true,
              'hidden' => true,
              'semantic_type' => { ':array' => 'host_address_ipv4' }
            },
            'fqdn' => {
              'required' => false,
              'read_only' => true,
              'is_port' => true,
              'cannot_change' => false,
              'data_type' => 'string',
              'display_name' => 'fqdn',
              'dynamic' => true,
              'hidden' => true
            },
            'node_components' => {
              'required' => false,
              'read_only' => true,
              'is_port' => true,
              'cannot_change' => false,
              'data_type' => 'json',
              'display_name' => 'node_components',
              'dynamic' => true,
              'hidden' => true
            }
          },
          'node_interface' => {
            'eth0' => { 'type' => 'ethernet', 'display_name' => 'eth0' }
          }
        }
      end
    end
  end
end; end