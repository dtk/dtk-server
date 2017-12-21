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
      require_relative('content/delete_mixin')
      require_relative('content/insert_action_helper')
      require_relative('content/action_match')
      require_relative('content/raw_form')
      require_relative('content/serialized_content_array')

      include DeleteMixin
      include Serialization
      include Stage::InterNode::Factory::StageName

      def initialize(object = nil, actions = [], opts = {})
        super()
        @subtask_order = opts[:subtask_order]
        @custom_name   = opts[:custom_name]
        create_stages!(object, actions, opts) if object
      end

      def serialization_form(opts = {})
        ret = nil
        subtasks = map { |internode_stage| internode_stage.serialization_form(opts.merge(subtask_order: opts[:subtask_order])) }.compact
        return ret if subtasks.empty?

        # Dont put in sequential block if just single stage and Constant::Sequential
        normalized_subtasks = 
          if subtasks.size == 1
            subtasks.first.inject({}) { |h, (k, v)| k == :name ? h : h.merge(k => v) }
          else
            { Field::Subtasks => subtasks }
        end
        ret = {}
        ret.merge!(name: @custom_name) if @custom_name
        ret.merge!(Field::SubtaskOrder => @subtask_order) if @subtask_order
        ret.merge(normalized_subtasks)
      end

      def create_subtask_instances(task_mh, assembly_idh)
        ret = []
        return ret if empty?
        all_actions = []
        each_internode_stage do |internode_stage, stage_index|
          task_hash = {
            display_name: internode_stage.name || DefaultNameProc.call(internode_stage, stage_index, size == 1),
            temporal_order: 'concurrent'
          }

          internode_stage.has_breakpoint?
          task_hash.merge!(breakpoint: internode_stage.breakpoint, retry: internode_stage.retry)          
          # if internode_stage.respond_to?(:has_breakpoint?) and internode_stage.first[1].first.first[:breakpoint]
          #   task_hash.merge!(breakpoint: true)
          #   Log.info("Found breakpoint")
          # end
          internode_stage_task = Task.create_stub(task_mh, task_hash)
          all_actions += internode_stage.add_subtasks!(internode_stage_task, stage_index, assembly_idh)
          ret << internode_stage_task
        end
        all_actions.each do |a|
          Log.debug("Runing action #{a[:state_change_types]} on node #{a[:node][:display_name]} type #{a[:node][:type]}")
        end
        attr_mh = task_mh.createMH(:attribute)
        Task::Action::ConfigNode.add_attributes!(attr_mh, all_actions)
        ret
      end

      def self.create_from_component_action(new_cmp_action, assembly)
        action_list = ActionList::ConfigComponents.get(assembly)
        ret = new
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
                last_internode_stage.has_action_with_method?
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

      def self.reify(serialized_content)
        RawForm.new(serialized_content)
      end

      # opts can have keys:
      #  :just_parse (Boolean)
      #  ...
      def self.parse_and_reify(serialized_content, actions, opts = {})
        # normalize to handle case where single stage, but not folded under subtasks
        SerializedContentArray.normalize(serialized_content, actions, opts)
      end

      def each_internode_stage(&block)
        each_with_index { |internode_stage, i| block.call(internode_stage, i + 1) }
      end

      def add_ndx_action_index!(hash, indexed_action)
        self.class.add_ndx_action_index!(hash, indexed_action)
      end
      def self.add_ndx_action_index!(hash, indexed_action)
        fail Error, "Unexpected that the following action does not have an index: #{indexed_action.inspect}" unless indexed_action.index
        (hash[indexed_action.node_id] ||= []) << indexed_action.index
        hash
      end

      # if template content includes action, ActionMatch is found
      def includes_action?(indexed_action)
        # ndx_action_indexes has node id as index and action_index array as values 
        ndx_action_indexes = add_ndx_action_index!({}, indexed_action)
        return nil if ndx_action_indexes.empty?
        each_internode_stage do |internode_stage, stage_index|
          if action_match = internode_stage.includes_action?(indexed_action, ndx_action_indexes: ndx_action_indexes) 
            action_match.internode_stage_index = stage_index
            return action_match
          end
        end
        nil
      end

      private

      def internode_stage(internode_stage_index)
        if internode_stage_index == :last
          last
        else
          self[internode_stage_index - 1]
        end
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
      #  :subtask_order
      #  ...
      def create_stages_from_serialized_content!(serialized_content_array, actions, opts = {})
        serialized_content_array.each do |serialized_content|
          if stage = Stage::InterNode.parse_and_reify?(serialized_content, actions, opts)
            stage.add_to_template_content!(self, serialized_content, just_parse: opts[:just_parse])
          end
        end
      end

      def create_stages_from_temporal_constraints!(temporal_constraints, actions, opts = {})
        default_stage_name_proc = { internode_stage_name_proc: DefaultNameProc }
        if opts[:node_centric_first_stage]
          node_centric_actions = actions.select { |a| a.source_type == :node_group }
          # TODO:  get :internode_stage_name_proc from node group field  :task_template_stage_name
          opts_x = { internode_stage_name_proc: DefaultNodeGroupNameProc }.merge(opts)
          create_stages_from_temporal_constraints_aux!(temporal_constraints, node_centric_actions, opts_x)

          assembly_actions = actions.select { |a| a.source_type == :assembly }
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
        existing_num_stages = size
        new_stages = []
        # before_index_hash gets destroyed in while loop
        until done
          if before_index_hash.empty?
            done = true
          else
            stage_action_indexes = before_index_hash.ret_and_remove_actions_not_after_any!
            if stage_action_indexes.empty?
              # TODO: see if any other way there can be loops
              fail ErrorUsage.new('Loop detected in temporal orders')
            end

            stage_action_indexes.each do |stage_action_index|
              internode_stage = stage_factory.create([stage_action_index])
              self << internode_stage
              new_stages << internode_stage
            end
            # TODO: DTK-3382: removing below for above so dont have multi action stages
            #internode_stage = stage_factory.create(stage_action_indexes)
            #self << internode_stage
            #new_stages << internode_stage
          end
        end
        set_internode_stage_names!(new_stages, opts[:internode_stage_name_proc])
        self
      end

      def set_internode_stage_names!(new_stages, internode_stage_name_proc)
        return unless internode_stage_name_proc
        is_single_stage = (new_stages.size == 1)
        new_stages.each_with_index do |internode_stage, i|
          unless internode_stage.name
            stage_index = i + 1
            internode_stage.name = internode_stage_name_proc.call(internode_stage, stage_index, is_single_stage)
          end
        end
      end
    end
  end
end; end
