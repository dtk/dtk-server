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
    class InterNode < ::Hash
      include Serialization
      # 'include Serialization' must be done first
      require_relative('inter_node/factory')
      require_relative('inter_node/multi_node')
      require_relative('inter_node/nested_subtask')

      def initialize(name = nil, breakpoint = nil)
        super()
        @name = name
      end
      attr_accessor :name

      def self.create_from_single_action(action, opts = {})
        new(stage_name(action, opts)).add_new_execution_block_for_action!(action, opts)
      end

      def self.stage_name(action, opts = {})
        if opts[:add_delete_action]
          "delete component #{action.component_type()}"
        else
          "component #{action.component_type()}"
        end
      end
      private_class_method :stage_name

      # returns all actions generated
      # This can be over-written
      def add_subtasks!(parent_task, internode_stage_index, assembly_idh = nil)
        ret = []
        each_node_actions do |node_actions|
          # TODO: DTK-2938: removed but need to be replaced with logic that inserts delete actions for nodes
          # if node_actions.is_node_component_task?
          #  add_delete_node_subtasks(parent_task, node_actions, ret)
          if false
          else
            if action = node_actions.add_subtask!(parent_task, internode_stage_index, assembly_idh)
              ret << action
              # TODO: DTK-2680: Aldin
              #  Not high priority, but better to take this special purpose logic out of here and
              #  instead when creating the delete workflow explicitly put in the cleanup task
              #   so this would go in lib/common_dsl/object_logic/assembly/component/diff/delete/task_template/splice_in_delete_action.rb
              if is_component_delete_action?(action)
                add_component_cleanup_task?(parent_task, node_actions, ret, action)
              end
            end
          end
        end
        ret
      end

      # opts can have keys:
      #   :just_parse
      # This can be over-written
      def add_to_template_content!(template_content, serialized_content, opts = {})
        unless empty?
          template_content << self 
        else
          # if opts[:just_parse] then stage will be empty
          unless opts[:just_parse]
            # TODO: might pass in option to indicate whether this should raise error or not
            # This is reached if component is not on any nodes
            Log.info_pp(["The following workflow stage has components not on any node", serialized_content])
          end
        end
      end

      # opts can have keys:
      #   :ndx_action_indexes
      def includes_action?(indexed_action, opts = {})
        ndx_action_indexes = opts[:ndx_action_indexes] || Content.add_ndx_action_index!({}, indexed_action)
        action_match = Content::ActionMatch.new(indexed_action)
        if find_earliest_match?(action_match, ndx_action_indexes)
          action_match
        end
      end

      # can be over-written
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

      # can be over-written
      def delete_action!(action_match)
        node_id = action_match.action.node_id
        if node_action = self[node_id]
          if :empty == node_action.delete_action!(action_match)
            delete(node_id)
            :empty if empty?()
          end
        end
      end

      # can be over-written
      def delete_components_on_node!(node)
        node_id = node.id
        if node_action = self[node_id]
          delete(node_id)
          :empty if empty?()
        end
      end

      # TODO: DTK-2759: thnk this need to be overwritten for nested task
      def splice_in_action!(action_match, insert_point)
        unless node_id = action_match.insert_action.node_id
          fail Error.new('Unexpected that node_id is nil')
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

      # def has_breakpoint?
      #   @breakpoint
      # end


      def serialization_form(opts = {})
        subtasks = map_node_actions { |node_actions| node_actions.serialization_form(opts) }.compact
        return nil if subtasks.empty?

        ret = serialized_form_with_name()

        # Dont put in concurrent block if there is just one node
        if subtasks.size == 1
          ret.merge(subtasks.first)
        else
          ret.merge(Field::SubtaskOrder => opts[:subtask_order]||Constant::Concurrent, Field::Subtasks => subtasks)
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
        # 4) a nested subtask

        # action_list nil can be passed if just concerned with parsing
        if action_list.nil?
          unless opts[:just_parse]
            Log.error("Unexpected that action_list.nil? while opts[:just_parse] is not true")
          end
        end

        if multi_node_type = parse_and_reify_is_multi_node_type?(serialized_content)
          MultiNode.parse_and_reify(multi_node_type, serialized_content, action_list, opts)
        elsif serialized_content[Field::Subtasks]
          NestedSubtask.parse_and_reify(serialized_content, action_list, opts)
        else
          normalized_content = serialized_content[Field::Subtasks] || [serialized_content]
          ret = parse_and_ret_normalized_content(normalized_content, serialized_content, action_list, opts)          
          !ret.empty? && ret
        end
      end

      def self.parse_and_ret_normalized_content(normalized_content, serialized_content, action_list, opts = {})
        ret = normalized_content.inject(InterNode.new(serialized_content[:name])) do |h, serialized_node_actions|
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
          node_actions ? h.merge(node_actions) : h
        end
        ret
      end

      def add_new_execution_block_for_action!(action, opts = {})
        # leveraging Stage::IntraNode::ExecutionBlocks.parse_and_reify(node_actions,node_name,action_list) for this
        node_actions = { Constant::OrderedComponents => [calculate_ordered_components(action, opts)] }
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

      def add_delete_node_subtasks(parent_task, node_actions, ret)
        n_node            = node_actions.node
        assembly_instance = n_node.get_assembly?
        opts              = Opts.new(delete_action: 'delete_node', delete_params: [n_node.id_handle])

        parent_task[:display_name] = "delete node #{n_node.get_field?(:display_name)}"
        # TODO: :temporal_order should probably be concurrent
        parent_task[:temporal_order] = 'sequential'

        command_and_control_action = Task.create_for_command_and_control_action(assembly_instance, 'destroy_node?', n_node[:id], n_node, opts.merge(return_executable_action: true))
        sub_task = Task.create_stub(parent_task.model_handle(), executable_action: command_and_control_action, display_name: 'destroy node')
        parent_task.add_subtask(sub_task)
        ret << command_and_control_action

        cleanup  = Task::Action::Cleanup.create_hash(assembly_instance, nil, n_node, opts)
        sub_task = Task.create_stub(parent_task.model_handle(), executable_action: cleanup, display_name: 'cleanup')
        parent_task.add_subtask(sub_task)
        ret << cleanup
      end


      def is_component_delete_action?(action)
        if action_method = action.action_method?
          action_method[:method_name].eql?('delete')
        end
      end

      def add_component_cleanup_task?(parent_task, node_actions, ret, action)
        if cmp_action = action.component_actions.first
          component         = cmp_action.component
          if component.get_field?(:to_be_deleted)
            n_node            = node_actions.node
            assembly_instance = n_node.get_assembly?
            opts = Opts.new(delete_action: 'delete_component', delete_params: [component.id_handle.merge(guid: component[:id]), n_node[:id]])

            parent_task[:temporal_order] = 'sequential'

            cleanup  = Task::Action::Cleanup.create_hash(assembly_instance, component, n_node, opts.merge(remove_delete_action: true))
            sub_task = Task.create_stub(parent_task.model_handle(), executable_action: cleanup, display_name: 'cleanup')
            parent_task.add_subtask(sub_task)
            ret << cleanup
          end
        end
      end

      def calculate_ordered_components(action, opts = {})
        if action.component_type.eql?("ec2::node[#{action.node_name}]") || opts[:add_delete_action]
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
