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
  class NodeComponent
    class InstanceAttributes < ::Hash
      require_relative('instance_attributes/node_group_helper')

      module ClassMixin
        def instance_id(node)
          InstanceAttributes.instance_id(node)
        end
      end

      module Mixin
        # returns an InstanceAttributes object
        def instance_attributes
          fail Error, "The method instance_attributes should not be called on a node group" if node.is_node_group?
          self.class::InstanceAttributes.new(node, attribute_name_value_hash)
        end

        # Returns an array of InstanceAttributes objects
        def instance_attributes_array
          ret = []
          fail Error, "The method instance_attributes_array should only be called on node group" unless node.is_node_group?
          node_group_helper = NodeGroupHelper.new(self)
          node.get_node_group_members.each_with_index do |node_group_member, index|
            ret << self.class::InstanceAttributes.new(node_group_member, node_group_helper.attribute_name_value_hash(index))
          end
          ret
        end

        def node_is_running?
          instance_attributes.node_is_running?
        end
      end
      
      def initialize(node, attributes_name_value_hash)
        super()
        name_value_hash = iaas_normalize(attributes_name_value_hash)
        replace(name_value_hash.inject(display_name_hash(node)) { |h, (n, v)| h.merge(n.to_sym => v) })
        @node = node
      end
      attr_reader :node
      
      def value?(name)
        self[name.to_sym]
      end
      
      def value(name)
        value?(name) || fail(Error, "Unexpected that attribute '#{name}' has a nil value")
      end
      
      def self.instance_id(node_or_node_group_member)
        instance_attributes(node_or_node_group_member).value(:instance_id)
      end

      def node_is_running?
        instance_state_is_running_values.include?(instance_state?)
      end

      def instance_state?
        value?(:instance_state)
      end

      def attribute?(name)
        self.node.get_node_attribute?(name)
      end

      private

      def self.instance_attributes(node_or_node_group_member)
        if node_group_member = node_or_node_group_member.node_group_member?
          node_group = node_group_member.node_group_parent
          node_group.node_component.instance_attributes_array[node_group_member.index - 1]
        else
          node_or_node_group_member.node_component.instance_attributes
        end
      end
      
      def iaas_normalize(attributes_name_value_hash)
        fail Error::NoMethodForConcreteClass.new(self.class)
      end

      def instance_state_is_running_values
        fail Error::NoMethodForConcreteClass.new(self.class)
      end

      def display_name_hash(node, opts = {})
        { display_name: node.assembly_node_print_form }
      end
      
    end
  end
end

