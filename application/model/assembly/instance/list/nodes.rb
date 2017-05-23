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
  module Assembly::Instance::List
    class Nodes
      module Mixin

        private
        def list_nodes(opts = Opts.new)
          nodes = get_nodes.reject { |node| node.is_assembly_wide_node? }

          NodeComponent.node_components(nodes, self).inject([]) do |a, node_component| 
            to_add = nil
            if node_component.node.is_node_group?
              to_add = node_component.instance_attributes_array.map do |instance_attributes|
                # There will be an element for each node group member
                Nodes.new(node_component, instance_attributes).node_hash_list_form
              end
            else
              to_add = [Nodes.new(node_component, node_component.instance_attributes).node_hash_list_form]
            end
            a + to_add
          end.sort { |a, b| a[:display_name] <=> b[:display_name] }
        end
      end

      def initialize(base_node_component, instance_attributes)
        @base_node_component = base_node_component
        @instance_attributes = instance_attributes
      end

      def node_hash_list_form
        { 
          :id               => instance_attributes.node.id,
          :display_name     => instance_value(:display_name),
          :instance_id      => instance_value?(:instance_id),
          :instance_state   => instance_value?(:instance_state), 
          :os_type          => base_value?(:os_type),
          :dns_address      => dns_address,
          :size             => base_value?(:size)
        }
      end
      
      private
      
      attr_reader :base_node_component, :instance_attributes
      
      def dns_address
        host_addresses_ipv4 = instance_value?(:host_addresses_ipv4)
        host_addresses_ipv4 && host_addresses_ipv4.first
      end
      
      def instance_value?(attribute_name)
        instance_attributes.value?(attribute_name)
      end
      def instance_value(attribute_name)
        instance_value?(attribute_name) || fail("Unexpected that node attribute '#{attribute_name}' is nil")
      end
      
      def base_value?(attribute_name)
        base_node_component.attribute_value?(attribute_name)
      end
      
    end
  end
end
