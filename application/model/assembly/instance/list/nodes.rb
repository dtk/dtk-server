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
          nodes = get_nodes__expand_node_groups(opts.merge(remove_node_groups: false)).reject do |node|
            # remove assembly wide nodes and soft-deleted node group members
            node.is_assembly_wide_node? or node[:ng_member_deleted] 
          end
          
          NodeComponent.node_components(nodes, self).map do |node_component| 
            Nodes.new(node_component, self).list_form
          end.sort { |a, b| a.display_name <=> b.display_name }
        end
      end

      def initialize(node_component, assembly_instance)
        @node_component    = node_component
        @node              = node_component.node
        @assembly_instance = assembly_instance
      end

      def list_form
        node[:display_name]      = node.assembly_node_print_form
        node[:admin_op_status]   = admin_op_status
        node[:dtk_client_type]   = dtk_client_type
        node[:dtk_client_hidden] = dtk_context_hidden
        node[:os_type]           = component_attribute_value(:os_type)

        external_ref = node[:external_ref] ||= {}
        external_ref[:dns_name]    = dns_name
        external_ref[:instance_id] = component_attribute_value(:instance_id)
        external_ref[:size]        = component_attribute_value(:size)

        set_target_iaas_properties!
        
        node.sanitize!
      end

      private

      attr_reader :node, :node_component, :assembly_instance
      
      def admin_op_status
        if node.is_node_group?
          nil
        else
          # TODO: DTK-2967: below hard-wired to ec2 attribute instance_state
          component_attribute_value(:instance_state)
        end
      end

      def dns_name
        host_addresses_ipv4 = component_attribute_value(:host_addresses_ipv4)
        host_addresses_ipv4 && host_addresses_ipv4.first
      end

      # TODO: this might not be needed any more
      def set_target_iaas_properties!
        if target = node[:target]
          if target[:iaas_properties]
            target[:iaas_properties][:security_group] ||=
              target[:iaas_properties][:security_group_set].join(',') if target[:iaas_properties][:security_group_set]
          end
        end
      end

      def dtk_client_type
        # if node is not part of node group we set nil
        is_node_group? ? :node_group : is_node_group_member? ? :node_group_node : nil
      end

      def dtk_context_hidden
        # remove node group or assembly wide node from list commands
        is_node_group? || is_assembly_wide_node?
      end

      def is_assembly_wide_node? 
        node.is_assembly_wide_node?
      end

      def is_node_group?
        node.is_node_group?
      end
      
      def is_node_group_member?
        assembly_instance.is_node_group_member?(node.id_handle)
      end
      
      def component_attribute_value(attribute_name)
        node_component.attribute_value(attribute_name)
      end

    end
  end
end
