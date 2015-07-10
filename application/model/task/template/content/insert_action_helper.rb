module DTK; class Task; class Template
  class Content
    class InsertActionHelper
      r8_nested_require('insert_action_helper', 'insert_at_end')

      def self.create(new_action, action_list, gen_constraints_proc = nil, insert_strategy = nil)
        insert_strategy_class(insert_strategy).new(new_action, action_list, gen_constraints_proc)
      end

      def insert_action?(template_content)
        unless template_content.includes_action?(@new_action)
          compute_before_after_relations!()
          insert_action!(template_content)
        end
      end

      private

      def initialize(new_action, action_list, gen_constraints_proc = nil, _insert_strategy = nil)
        @new_action = action_list.find { |a| a.match_action?(new_action) }
        @new_action_node_id = new_action.node_id
        @gen_constraints_proc = gen_constraints_proc
        @ndx_action_indexes = NdxActionIndexes.new()
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
        insert_at_end: InsertAtEnd
      }

      def compute_before_after_relations!
        unless new_action_index = @new_action.index
          # if @new_action does not have an index it means that it is not in action list
          Log.error('Cannot find action in action list; using no constraints')
          return
        end

        temporal_constraints = @gen_constraints_proc && @gen_constraints_proc.call()
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
