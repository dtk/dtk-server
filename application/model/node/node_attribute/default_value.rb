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
module DTK; class Node
  class NodeAttribute
    module DefaultValue
      def self.host_addresses_ipv4
        {
          required: false,
          read_only: true,
          is_port: true,
          cannot_change: false,
          data_type: 'json',
          value_derived: [nil],
          semantic_type_summary: 'host_address_ipv4',
          display_name: 'host_addresses_ipv4',
          dynamic: true,
          hidden: true,
          semantic_type: { ':array' => 'host_address_ipv4' }
        }
      end

      def self.fqdn
        {
          required: false,
          read_only: true,
          is_port: true,
          cannot_change: false,
          data_type: 'string',
          display_name: 'fqdn',
          dynamic: true,
          hidden: true
        }
      end

      def self.node_components
        {
          required: false,
          read_only: true,
          is_port: true,
          cannot_change: false,
          data_type: 'json',
          display_name: 'node_components',
          dynamic: true,
          hidden: true
        }
      end
    end
  end
end; end