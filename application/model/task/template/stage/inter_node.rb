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
module DTK; class Task; class Template
  class Stage
    class InterNode < Hash
      r8_nested_require('inter_node', 'factory')
      r8_nested_require('inter_node', 'multi_node')
      include Serialization

      def initialize(name = nil)
        super()
        @name = name
      end
      attr_accessor :name

      def self.create_from_single_action(action)
        new(stage_name(action)).add_new_execution_block_for_action!(action)
      end

      def self.stage_name(action)
        "component #{action.component_type()}"
      end
      private_class_method :stage_name

      # returns all actions generated
      def add_subtasks!(parent_task, internode_stage_index, assembly_idh = nil)
        ret = []
        each_node_actions do |node_actions|
          if action = node_actions.add_subtask!(parent_task, internode_stage_index, assembly_idh)
            ret << action
          end
        end
        ret
      end

      def find_earliest_match?(action_match, ndx_action_indexes)
        ndx_action_indexes.each_pair do |node_id, action_indexes|
          if node_actions = self[node_id]
            if node_actions.find_earliest_match?(action_match, action_indexes)
              action_match.in_multinode_stage = true if is_a?(MultiNode)
              return true
            end
          end
        end
        false
      end

      def has_action_with_method?
        !!values.find(&:has_action_with_method?)
      end

      def delete_action!(action_match)
        node_id = action_match.action.node_id
        unless node_action = self[node_id]
          fail Error.new('Unexepected that no node action can be found')
        end
        if :empty == node_action.delete_action!(action_match)
          delete(node_id)
          :empty if empty?()
        end
      end

      def splice_in_action!(action_match, insert_point)
        unless node_id = action_match.insert_action.node_id
          fail Error.new('Unexepected that node_id is nil')
        end
        case insert_point
          when :end_last_execution_block
            if node_action = self[node_id]
              node_action.splice_in_action!(action_match, insert_point)
            else
              add_new_execution_block_for_action!(action_match.insert_action)
            end
          when :before_action_pos
            unless node_action = self[node_id]
              fail Error.new("Illegal node_id (#{action_match.node_id})")
            end
            node_action.splice_in_action!(action_match, insert_point)
          else fail Error.new("Unexpected insert_point (#{insert_point})")
        end
      end
      # TODO: have above subsume below
      def splice_in_at_beginning!(internode_stage)
        ndx_splice_in_node_ids = internode_stage.node_ids().inject({}) { |h, node_id| h.merge(node_id => true) }
        each_node_id do |node_id|
          if matching = internode_stage[node_id]
            self[node_id].splice_in_at_beginning!(matching)
            ndx_splice_in_node_ids.delete(node_id)
          end
        end
        ndx_splice_in_node_ids.keys.each do |node_id|
          merge!(node_id => internode_stage[node_id])
        end
        self
      end

      def serialization_form(opts = {})
        subtasks = map_node_actions { |node_actions| node_actions.serialization_form(opts) }.compact
        return nil if subtasks.empty?

        ret = serialized_form_with_name()

        # Dont put in concurrent block if there is just one node
        if subtasks.size == 1
          ret.merge(subtasks.first)
        else
          ret.merge(Field::TemporalOrder => Constant::Concurrent, Field::Subtasks => subtasks)
        end
      end

      # opts can have keys:
      #  :just_parse (Boolean)
      #  ...
      def self.parse_and_reify?(serialized_content, action_list, opts = {})
        # content could be either
        # 1) a concurrent block with multiple nodes,
        # 2) a single node,
        # 3) a multi-node specification

        # action_list nil can be passed if just concerned with parsing
        if action_list.nil?
          unless opts[:just_parse]
            Log.error("Unexpected that action_list.nil? while opts[:just_parse] is not true")
          end
        end

        if multi_node_type = parse_and_reify_is_multi_node_type?(serialized_content)
          return MultiNode.parse_and_reify(multi_node_type, serialized_content, action_list, opts)
        end

        normalized_content = serialized_content[Field::Subtasks] || [serialized_content]
        ret = normalized_content.inject(new(serialized_content[:name])) do |h, serialized_node_actions|
          unless node_name = Constant.matches?(serialized_node_actions, :Node)
            if Constant.matches?(serialized_node_actions, :Nodes)
              fail ParsingError.new("Within nested subtask only '#{Constant::Node}' and not '#{Constant::Nodes}' keyword can be used")
            end
            fail ParsingError.new('Missing node reference in: ?1', serialized_node_actions)
          end
          node_id = 0 #dummy value when just used for parsing
          if action_list
            unless node_id = action_list.find_matching_node_id(node_name)
              fail ParsingError.new("The following element(s) cannot be resolved with respect to the assembly's nodes and components: ?1", serialized_content)
            end
          end
          node_actions = parse_and_reify_node_actions?(serialized_node_actions, node_name, node_id, action_list, opts)
          node_actions ? h.merge(node_actions) : {}
        end
        !ret.empty? && ret
      end

      def add_new_execution_block_for_action!(action)
        # leveraging Stage::IntraNode::ExecutionBlocks.parse_and_reify(node_actions,node_name,action_list) for this
        node_actions = { Constant::OrderedComponents => [calculate_ordered_components(action)] }
        node_name = action.node_name()
        action_list = ActionList.new([action])
        merge!(action.node_id => Stage::IntraNode::ExecutionBlocks.parse_and_reify(node_actions, node_name, action_list))
      end

      def each_node_id(&block)
        each_key { |node_id| block.call(node_id) }
      end

      def node_ids
        keys()
      end

      private

      def calculate_ordered_components(action)
        if action.component_type.eql?("ec2::node[#{action.node_name}]")
          "#{action.component_type}.delete"
        else
          action.component_type
        end
      end

      def serialized_form_with_name
        @name ? OrderedHash.new(name: @name) : OrderedHash.new
      end

      def self.parse_and_reify_is_multi_node_type?(serialized_content)
        # only look at leaf subtasks tasks
        unless leaf_subtask?(serialized_content)
          if ret = Constant.matches?(serialized_content, :Nodes)
            ret
          elsif !Constant.matches?(serialized_content, :Node)
            Constant::AllApplicable
          end
        end
      end

      def self.leaf_subtask?(serialized_content)
        Constant.matches?(serialized_content, :Subtasks)
      end

      def self.parse_and_reify_node_actions?(node_actions, node_name, node_id, action_list, opts = {})
        exec_blocks = Stage::IntraNode::ExecutionBlocks.parse_and_reify(node_actions, node_name, action_list, opts)
        # remove empty blocks
        exec_blocks.reject!(&:empty?)
        unless exec_blocks.empty?
          { node_id => exec_blocks }
        end
      end

      def each_node_actions(&block)
        each_value { |node_actions| block.call(node_actions) }
      end

      def map_node_actions(&block)
        values.map { |node_actions| block.call(node_actions) }
      end
    end
  end
end; end; end