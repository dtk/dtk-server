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
module DTK; module CommonDSL
  module ObjectLogic
    class Assembly
      class Node < ContentInputHash
        require_relative('node/diff')
        require_relative('node/attribute')

        def self.generate_content_input(assembly_instance)
          get_augmented_nodes(assembly_instance, without_soft_deleted_nodes: true).inject(ContentInputHash.new) do |h, aug_node|
            h.merge(aug_node.display_name => new.generate_content_input!(aug_node, without_soft_deleted_components: true))
          end
        end
        
        def generate_content_input!(aug_node, opts = {})
          set_id_handle(aug_node)
          aug_components = aug_node[:components] || []
          attributes = aug_node[:attributes] || []
          # :is_assembly_wide_node just used internally to server-side processing; so not using 'set' method
          self[:is_assembly_wide_node] = true if aug_node.is_assembly_wide_node?

          set?(:Attributes, Attribute.generate_content_input?(:node, attributes)) unless attributes.empty?
          set(:Components, Component.generate_content_input(aug_components, opts)) unless aug_components.empty?
          self
        end

        ### For diffs
        # opts can have keys:
        #  :service_instance
        #  :impacted_files
        def diff?(node_parse, qualified_key, opts)
          aggregate_diffs?(qualified_key, opts) do |diff_set|
            diff_set.add_diff_set? Attribute, val(:Attributes), node_parse.val(:Attributes)
            diff_set.add_diff_set? Component, val(:Components), node_parse.val(:Components)
            # TODO: need to add diffs on all subobjects
          end
        end

        # opts can have keys:
        #   :service_instance
        #   :impacted_files
        def self.diff_set(nodes_gen, nodes_parse, qualified_key, opts = {})
          diff_set_from_hashes(nodes_gen, nodes_parse, qualified_key, opts)
        end

        def self.node_has_been_created?(node)
          node.get_admin_op_status != 'pending'
        end

        CANONICAL_NODE_COMPONENT_TYPE = 'ec2__node'
        NODE_COMPONENT_TYPES = [CANONICAL_NODE_COMPONENT_TYPE, 'ec2__properties']
        def self.is_canonical_node_component?(component)
          component.get_field?(:component_type).eql?(CANONICAL_NODE_COMPONENT_TYPE)
        end
        def self.is_a_node_component?(component)
          NODE_COMPONENT_TYPES.include?(component.get_field?(:component_type))
        end

        private

        def self.get_augmented_nodes(assembly_instance, opts = {})
          assembly_instance_nodes = assembly_instance.get_nodes(:to_be_deleted)

          if opts[:without_soft_deleted_nodes]
            assembly_instance_nodes.reject!{ |node| node[:to_be_deleted] }
          end

          ndx_nodes = assembly_instance_nodes.inject({}) { |h, r| h.merge(r.id => r) }
          add_node_level_attributes!(ndx_nodes)
          add_augmented_components!(ndx_nodes)
          ndx_nodes.values
        end
        
        def self.add_node_level_attributes!(ndx_nodes)
          node_idhs = ndx_nodes.values.reject { |node| node.is_assembly_wide_node? }.map(&:id_handle)
          unless node_idhs.empty?
            ::DTK::Node.get_node_level_assembly_template_attributes(node_idhs).each do |r|
              node_id = r[:node_node_id]
              (ndx_nodes[node_id][:attributes] ||= []) << r
            end
            add_type_node_level_attribute!(ndx_nodes)
          end
        end

        def self.add_type_node_level_attribute!(ndx_nodes)
          # add 'type: group' for node groups
          node_groups = ndx_nodes.values.select { |node| node.is_node_group? }
          node_groups.each do |node_group|
            type_attribute = node_level_attribute(node_group, 'type', 'group')
            (ndx_nodes[node_group.id][:attributes] ||= []) << type_attribute
          end
        end

        def self.node_level_attribute(node, name, value)
          hash = {
            display_name: name,
            node_node_id: node.id,
            data_type: 'string',
            hidden: false,
            dynamic: false,
            value_asserted: value,
            value_derived: nil
          }
          ::DTK::Attribute.create_stub(node.model_handle(:attribute), hash)
        end
        
        def self.add_augmented_components!(ndx_nodes)
          ::DTK::Node::Instance.add_augmented_components!(ndx_nodes)
        end
        
      end
    end
  end
end; end

