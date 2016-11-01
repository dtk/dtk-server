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
  class Content
    class InsertActionHelper
      require_relative('insert_action_helper/insert_at_end')
      require_relative('insert_action_helper/insert_at_start_in_subtask')

      # opts can have keys
      #   :gen_constraints_proc
      #   :insert_strategy
      def self.create(new_action, action_list, opts = {})
        insert_strategy_class(opts[:insert_strategy]).new(new_action, action_list, gen_constraints_proc: opts[:gen_constraints_proc])
      end

      def insert_action?(template_content)
        unless template_content.includes_action?(@new_action)
          compute_before_after_relations!
          insert_action!(template_content)
        end
      end
      # TODO: DTK-2680; Aldin: commented below out and temporarily put original in
      #  Curremtly what needs to be fixed is computing of @new_action
      #  Think there is a bug that does not match on new_action.method when new_action.is_a?(Action::WithMethod)
      #  What then happens is template_content.includes_action?(@new_action) succeds when it shouldnt 
      #  (e.g, there is a component.create action in task template while looking for a delete component
      # Rich: I may need to explain or even cleanup what is in action list; it was initially created before
      # we had actions with methods (just create) so create actions and others modeled differently

      # in lib/common_dsl/object_logic/assembly/component/diff/delete.rb  
#        if template_content.includes_action?(@new_action) && @add_delete_action
#          template_content.delete_explicit_action?(@new_action, @action_list)
#          compute_before_after_relations!
#          insert_action!(template_content, opts)
#        else
#        # unless template_content.includes_action?(@new_action)
#          compute_before_after_relations!
#          insert_action!(template_content)
#        end


      private

      # opts can have keys
      #   :gen_constraints_proc
      def initialize(new_action, action_list, opts = {})
        match_opts            = new_action.is_a?(Action::WithMethod) ? { class: Action::WithMethod } : {}
        @new_action           = action_list.find { |a| a.match_action?(new_action, match_opts) }
        @new_action_node_id   = new_action.node_id
        @gen_constraints_proc = opts[:gen_constraints_proc]
        @ndx_action_indexes   = NdxActionIndexes.new
        @action_list          = action_list
      end

      class NdxActionIndexes < Hash
        # These are of form
        #[:internode|:samenode][:before|:after]
        # which has value {node_id => [action_indexex],,,}
        def get(inter_or_same, before_or_after)
          (self[inter_or_same] || {})[before_or_after] || {}
        end

        def add(inter_or_same, before_or_after, action)
          pntr = ((self[inter_or_same] ||= {})[before_or_after] ||= {})
          Content.add_ndx_action_index!(pntr, action)
          self
        end
      end

      def self.insert_strategy_class(insert_strategy = nil)
        # default insert strategy is to put the new action in the latest existing internode stage at the latest point
        if insert_strategy
          unless ret = InsertStrategies[insert_strategy]
            fail Error.new("Illegal insert action strategy (#{insert_strategy})")
          end
          ret
        else
          InsertAtEnd
        end
      end

      InsertStrategies = {
        insert_at_end: InsertAtEnd,
        insert_at_start_in_subtask: InsertAtStartInSubtask
      }

      def compute_before_after_relations!
        unless new_action_index = @new_action.index
          # if @new_action does not have an index it means that it is not in action list
          Log.error('Cannot find action in action list; using no constraints')
          return
        end

        temporal_constraints = @gen_constraints_proc && @gen_constraints_proc.call
        return if (temporal_constraints || []).empty?

        temporal_constraints.each do |tc|
          if tc.before_action_index == new_action_index
            after_action = tc.after_action
            if after_action.node_id == @new_action_node_id
              add_ndx_action_index(:samenode, :after, after_action)
            else
              add_ndx_action_index(:internode, :after, after_action)
            end
          elsif tc.after_action_index == new_action_index
            before_action = tc.before_action
            if before_action.node_id == @new_action_node_id
              add_ndx_action_index(:samenode, :before, before_action)
            else
              add_ndx_action_index(:internode, :before, before_action)
            end
          end
        end
      end

      def get_ndx_action_indexes(inter_or_same, before_or_after)
        @ndx_action_indexes.get(inter_or_same, before_or_after)
      end

      def add_ndx_action_index(inter_or_same, before_or_after, action)
        @ndx_action_indexes.add(inter_or_same, before_or_after, action)
      end
    end
  end
end; end; end
