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
  class Stage; class IntraNode
    class ExecutionBlocks < Array
      include Serialization
      def add_subtask!(parent_task, internode_stage_index, assembly_idh = nil)
        executable_action = Task::Action::ConfigNode.create_from_execution_blocks(self, assembly_idh)
        executable_action.set_inter_node_stage!(internode_stage_index)
        sub_task = Task.create_stub(parent_task.model_handle(), executable_action: executable_action)
        parent_task.add_subtask(sub_task)
        executable_action
      end

      def is_node_component_task?
        if component = has_action_with_method? && (components.size == 1) && components.first
          Component::Domain::Node::Canonical.is_type_of?(component) 
        end
      end

      def find_earliest_match?(action_match, action_indexes)
        each_with_index do |eb, i|
          if eb.find_earliest_match?(action_match, action_indexes)
            action_match.execution_block_index = i + 1
            return true
          end
        end
        false
      end

      def has_action_with_method?
        !!find(&:has_action_with_method?)
      end

      def delete_action!(action_match)
        eb_index = action_match.execution_block_index()
        if :empty == execution_block(eb_index).delete_action!(action_match)
          delete_execution_block!(eb_index)
          :empty if empty?()
        end
      end

      def splice_in_action!(action_match, insert_point)
        case insert_point
          when :end_last_execution_block
            execution_block(:last).splice_in_action!(action_match, :end)
          when :before_action_pos
            execution_block(action_match.execution_block_index()).splice_in_action!(action_match, insert_point)
          else fail Error.new("Unexpected insert_point (#{insert_point})")
        end
      end
      # TODO: have above subsume below
      def splice_in_at_beginning!(execution_blocks)
        insert(0, *execution_blocks)
        self
      end

      def serialization_form(opts = {})
        opts_x = { no_node_name_prefix: true }.merge(opts)
        execution_blocks =  map { |eb| eb.serialization_form(opts_x) }.compact
        return nil if execution_blocks.empty?()

        ret = OrderedHash.new()
        if node_name = node_name()
          node_field_term = ((node() && node().is_node_group?()) ? Constant::NodeGroup : Constant::Node).to_sym
          ret[node_field_term] = node_name unless node_name.eql?('assembly_wide')
        end
        if execution_blocks.size == 1
          # if single execution block then we remove this level of nesting
          ret.merge(execution_blocks.first)
        else
          ret.merge(Field::ExecutionBlocks =>  execution_blocks)
        end
      end
      def self.parse_and_reify(serialized_node_actions, node_name, action_list, opts = {})
        # normalize to take into account it may be single execution block
        normalized_content = serialized_node_actions.is_a?(Hash) && serialized_node_actions[Field::ExecutionBlocks]
        normalized_content ||= [serialized_node_actions]
        ret = new()
        #normalized_content.each  { |serialized_eb| ret << ExecutionBlock::Ordered.parse_and_reify(serialized_eb, node_name, node_retry, action_list, opts) }
        normalized_content.each do |serialized_eb|
          ret << ExecutionBlock::Ordered.parse_and_reify(serialized_eb, node_name, action_list, opts)
        end
        ret
      end

      def order_each_block(intra_node_constraints)
        ret = self.class.new()
        each do |unordered_exec_block|
          ret << unordered_exec_block.order(intra_node_constraints)
        end
        ret
      end

      def intra_node_stages
        ret = []
        return ret if empty?()
        if find { |eb| !eb.is_a?(ExecutionBlock::Ordered) }
          fail Error.new('The method ExecutionBlocks#intra_node_stages can only be called if all its elements are ordered')
        end
        map(&:intra_node_stages)
      end

      def node
        # all the elements have same node so can just pick first
        first && first.node()
      end

      def node_name
        (node() || {})[:display_name]
      end

      def components
        ret = []
        each { |exec_block| ret += exec_block.components() }
        ret
      end

      def components_hash_with(opts = {})
        ret = []
        each { |exec_block| ret += exec_block.components_hash_with(opts) }
        ret
      end

      private

      def execution_block(execution_block_index)
        if execution_block_index == :last
          last()
        else
          self[execution_block_index - 1]
        end
      end

      def delete_execution_block!(execution_block_index)
        delete_at(execution_block_index - 1)
      end
    end
  end; end
end; end; end
