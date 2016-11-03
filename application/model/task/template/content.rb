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
module DTK; class Task
  class Template
    class Content < ::Array
      require_relative('content/insert_action_helper')
      require_relative('content/action_match')

      include Serialization
      include Stage::InterNode::Factory::StageName

      def initialize(object = nil, actions = [], opts = {})
        super()
        if object
          create_stages!(object, actions, opts)
        end
      end

      def create_subtask_instances(task_mh, assembly_idh)
        ret = []
        return ret if empty?()
        all_actions = []
        each_internode_stage do |internode_stage, stage_index|
          task_hash = {
            display_name: internode_stage.name || DefaultNameProc.call(stage_index, size == 1),
            temporal_order: 'concurrent'
          }
          internode_stage_task = Task.create_stub(task_mh, task_hash)
          all_actions += internode_stage.add_subtasks!(internode_stage_task, stage_index, assembly_idh)
          ret << internode_stage_task
        end
        attr_mh = task_mh.createMH(:attribute)
        Task::Action::ConfigNode.add_attributes!(attr_mh, all_actions)
        ret
      end

      def self.create_from_component_action(new_cmp_action, assembly)
        action_list = ActionList::ConfigComponents.get(assembly)
        ret = new()
        ret.insert_action?(new_cmp_action, action_list)
        ret
      end

      # if action is not included in task template than insert the action in this object and return updated object
      # else return nil
      # opts can have keys:
      #   :gen_constraints_proc
      #   :insert_strategy
      def insert_action?(new_action, action_list, opts = {})
        insert_action_helper = InsertActionHelper.create(new_action, action_list, opts)
        insert_action_helper.insert_action?(self)
      end

      # if action is explicitly included in task template then delete the action from this object and return updated object
      # else return nil
      def delete_explicit_action?(action, action_list, opts = {})
        opts.merge!(class: Action::WithMethod) if action.is_a?(Action::WithMethod)
        if indexed_action = action_list.find { |a| a.match_action?(action, opts) }
          # TODO: DTK-2680: Aldin: put in a few sentences explaing this logic
          if action.is_a?(Action::WithMethod)
            indexed_action = action if indexed_action.component_type.eql?("ec2::node[#{indexed_action.node_name}]") || opts[:remove_delete_action]
          end
          if action_match = includes_action?(indexed_action)
            # TODO: DTK-2732: look at whether when it is not in_multinode_stage whether we should still delete if this component is only instance
            # that matches this step. 
            # note: in_multinode_stage is somehwta in misnomer in that it can be true when step only refers to assembly wide
            if action_match.is_assembly_wide? or !action_match.in_multinode_stage
              delete_action!(action_match)
              self
            end
          end
        end
      end

      def splice_in_action!(action_match, insert_point, opts = {})
        case insert_point
          when :before_internode_stage
            if action_match.internode_stage_index == 1
              new_internode_stage = Stage::InterNode.create_from_single_action(action_match.insert_action, opts)
              insert(action_match.internode_stage_index - 1, new_internode_stage)
            else
              internode_stage(action_match.internode_stage_index).splice_in_action!(action_match, :end_last_execution_block)
            end
          when :before_action_pos
            internode_stage(action_match.internode_stage_index).splice_in_action!(action_match, :before_action_pos)
          # TODO: currently this cannot be reached because using :add_as_new_last_internode_stage instead
          # if leave below in make it so under more cases a new stage is created
          when :end_last_internode_stage
            last_internode_stage = internode_stage(:last)
            # create new stage if last_internode_stage is
            # - multi node, or
            # - has explicit actions
            if last_internode_stage.is_a?(Stage::InterNode::MultiNode) ||
                last_internode_stage.has_action_with_method?()
              new_internode_stage = Stage::InterNode.create_from_single_action(action_match.insert_action, opts)
              self << new_internode_stage
            else
              last_internode_stage.splice_in_action!(action_match, :end_last_execution_block)
            end
          when :add_as_new_last_internode_stage
            new_internode_stage = Stage::InterNode.create_from_single_action(action_match.insert_action, opts)
            self << new_internode_stage
          else fail Error.new("Unexpected insert_point (#{insert_point})")
        end
      end
      # TODO: have above subsume below
      def splice_in_at_beginning!(template_content, opts = {})
        if opts[:node_centric_first_stage]
          insert(0, *template_content)
        else
          unless template_content.size == 1
            fail ErrorUsage.new('Can only splice in template content that has a single inter node stage')
          end
          first.splice_in_at_beginning!(template_content.first)
        end
        self
      end

      def serialization_form(opts = {})
        ret = nil
        subtasks = map { |internode_stage| internode_stage.serialization_form(opts) }.compact
        if subtasks.empty?()
          return ret
        end

        # Dont put in sequential block if just single stage
        if subtasks.size == 1
          subtasks.first.delete(:name)
          subtasks.first
        else
          {
            Field::TemporalOrder => Constant::Sequential,
            Field::Subtasks => subtasks
          }
        end
      end

      def self.reify(serialized_content)
        RawForm.new(serialized_content)
      end

      class RawForm
        def serialization_form(_opts = {})
          @serialized_content
        end

        def initialize(serialized_content)
          @serialized_content = serialized_content
        end
      end

      # opts can have keys:
      #  :just_parse (Boolean)
      #  ...
      def self.parse_and_reify(serialized_content, actions, opts = {})
        # normalize to handle case where single stage, but not folded under subtasks

        unless subtasks = Constant.matches?(serialized_content, :Subtasks) 
          subtasks = [] if parse_and_reify__empty_subtasks?(serialized_content)
        end

        normalized_subtasks =
          if subtasks
            has_multi_stages = (parse_and_reify__temporal_order(serialized_content) == Constant::Sequential)
            has_multi_stages ? subtasks : [{ Field::Subtasks => subtasks }]
          else
            [serialized_content]
          end

        new(SerializedContentArray.new(normalized_subtasks), actions, opts)
      end

      def self.parse_and_reify__temporal_order(serialized_content)
        if temporal_order = Constant.matches?(serialized_content, :TemporalOrder)
          temporal_order.to_sym 
        else
          # Default is Sequential
          Constant::Sequential
        end
      end

      def self.parse_and_reify__empty_subtasks?(serialized_content)
        # check if empty workflow by making sure it is not a stage directly not wrapped in subtask
        !Constant.matches?(serialized_content, :Subtasks) and !Constant.matches?(serialized_content, :ComponentsOrActions)
      end

      class SerializedContentArray < Array
        def initialize(array)
          super()
          array.each { |a| self << a }
        end
      end

      def each_internode_stage(&block)
        each_with_index { |internode_stage, i| block.call(internode_stage, i + 1) }
      end

      def add_ndx_action_index!(hash, action)
        self.class.add_ndx_action_index!(hash, action)
      end
      def self.add_ndx_action_index!(hash, action)
        (hash[action.node_id] ||= []) << action.index
        hash
      end

      def includes_action?(action)
        ndx_action_indexes = add_ndx_action_index!({}, action)
        return nil if ndx_action_indexes.empty?()
        each_internode_stage do |internode_stage, stage_index|
          action_match = ActionMatch.new(action)
          if internode_stage.find_earliest_match?(action_match, ndx_action_indexes)
            action_match.internode_stage_index = stage_index
            return action_match
          end
        end
        nil
      end

      private

      def delete_action!(action_match)
        internode_stage_index = action_match.internode_stage_index
        if :empty == internode_stage(internode_stage_index).delete_action!(action_match)
          delete_internode_stage!(internode_stage_index)
          :empty if empty?()
        end
      end

      def internode_stage(internode_stage_index)
        if internode_stage_index == :last
          last()
        else
          self[internode_stage_index - 1]
        end
      end

      def delete_internode_stage!(internode_stage_index)
        delete_at(internode_stage_index - 1)
      end

      def create_stages!(object, actions, opts = {})
        if object.is_a?(TemporalConstraints)
          create_stages_from_temporal_constraints!(object, actions, opts)
        elsif object.is_a?(SerializedContentArray)
          create_stages_from_serialized_content!(object, actions, opts)
        else
          fail Error.new("create_stages! does not treat argument of type (#{object.class})")
        end
      end

      # opts can have keys:
      #  :just_parse (Boolean)
      #  ...
      def create_stages_from_serialized_content!(serialized_content_array, actions, opts = {})
        serialized_content_array.each do |serialized_content|
          # TODO: DTK-2680: I [Rich] removed this because dont know how to use this
          # require 'debugger'
          # Debugger.wait_connection = true
          # Debugger.start_remote(nil, 7020)
          # debugger

          # TODO: DTK-2680: Aldin: I slightly modified so Stage::InterNode.parse_and_reify?(serialized_content, actions, opts) always returns
          #       subclass of InterNode, but kept logic that flattens it out
          #       logic is hidden in Stage::InterNode#add_to_template_content!
          if stage = Stage::InterNode.parse_and_reify?(serialized_content, actions, opts)
            stage.add_to_template_content!(self, serialized_content, just_parse: opts[:just_parse])
          end
        end
      end

      def create_stages_from_temporal_constraints!(temporal_constraints, actions, opts = {})
        default_stage_name_proc = { internode_stage_name_proc: DefaultNameProc }
        if opts[:node_centric_first_stage]
          node_centric_actions = actions.select { |a| a.source_type() == :node_group }
          # TODO:  get :internode_stage_name_proc from node group field  :task_template_stage_name
          opts_x = { internode_stage_name_proc: DefaultNodeGroupNameProc }.merge(opts)
          create_stages_from_temporal_constraints_aux!(temporal_constraints, node_centric_actions, opts_x)

          assembly_actions = actions.select { |a| a.source_type() == :assembly }
          create_stages_from_temporal_constraints_aux!(temporal_constraints, assembly_actions, default_stage_name_proc.merge(opts))
        else
          create_stages_from_temporal_constraints_aux!(temporal_constraints, actions, default_stage_name_proc.merge(opts))
        end
      end

      def create_stages_from_temporal_constraints_aux!(temporal_constraints, actions, opts = {})
        return if actions.empty?
        inter_node_constraints = temporal_constraints.select(&:inter_node?)

        stage_factory = Stage::InterNode::Factory.new(actions, temporal_constraints)
        before_index_hash = inter_node_constraints.create_before_index_hash(actions)
        done = false
        existing_num_stages = size()
        new_stages = []
        # before_index_hash gets destroyed in while loop
        until done
          if before_index_hash.empty?
            done = true
          else
            stage_action_indexes = before_index_hash.ret_and_remove_actions_not_after_any!()
            if stage_action_indexes.empty?()
              # TODO: see if any other way there can be loops
              fail ErrorUsage.new('Loop detected in temporal orders')
            end
            internode_stage = stage_factory.create(stage_action_indexes)
            self << internode_stage
            new_stages << internode_stage
          end
        end
        set_internode_stage_names!(new_stages, opts[:internode_stage_name_proc])
        self
      end

      def set_internode_stage_names!(new_stages, internode_stage_name_proc)
        return unless internode_stage_name_proc
        is_single_stage = (new_stages.size() == 1)
        new_stages.each_with_index do |internode_stage, i|
          unless internode_stage.name
            stage_index = i + 1
            internode_stage.name = internode_stage_name_proc.call(stage_index, is_single_stage)
          end
        end
      end
    end
  end
end; end
