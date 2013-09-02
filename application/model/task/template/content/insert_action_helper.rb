module DTK; class Task; class Template
  class Content
    class InsertActionHelper
      def self.create(new_action,action_list,temporal_constraints,insert_strategy=nil)
        insert_strategy_class(insert_strategy).new(new_action,action_list,temporal_constraints)
      end

     private
      def initialize(new_action,action_list,temporal_constraints,insert_strategy=nil)
        @new_action = new_action
        @new_action_node_id = new_action.node_id
        @ndx_action_indexes = NdxActionIndexes.new()
        compute_before_after_relations!(temporal_constraints,action_list)
      end

      class NdxActionIndexes < Hash
        #These are of form
        #[:internode|:samenode][:before|:after]
        # which has value {node_id => [action_indexex],,,}
        def get(inter_or_same,before_or_after)
          (self[inter_or_same]||{})[before_or_after]||{}
        end
        def add(inter_or_same,before_or_after,action)
          (((self[inter_or_same] ||= Hash.new)[before_or_after] ||= Hash.new)[action.node_id] ||= Array.new) << action.index
          self
        end
      end

      def self.insert_strategy_class(insert_strategy=nil)
        #default insert strategy is to put the new action in the latest existing internode stage at the latest point
        if insert_strategy 
          unless ret = InsertStrategies[insert_strategy]
            raise Error.new("Illegal insert action strategy (#{insert_strategy})")
          end
          ret
        else
          InsertAtEnd
        end
      end

      def compute_before_after_relations!(temporal_constraints,action_list)
        if temporal_constraints.empty? 
          return
        end
        #find and set the new action's index 
        if new_action_with_index = action_list.find{|a|a.match_action?(@new_action)}
          @new_action = new_action_with_index
        else
          Log.error("Cannot find action in action list; using no constraints")
          return
        end
        
        new_action_index = @new_action.index
        temporal_constraints.each do |tc|
          if tc.before_action_index == new_action_index
            after_action = tc.after_action
            if after_action.node_id == @new_action_node_id
              add_ndx_action_index(:samenode,:after,after_action)
            else
              add_ndx_action_index(:internode,:after,after_action)
            end
          elsif tc.after_action_index == new_action_index
            before_action = tc.before_action 
            if before_action.node_id == @new_action_node_id
              add_ndx_action_index(:samenode,:before,before_action)
            else
              add_ndx_action_index(:internode,:before,before_action)
            end
          end
        end
      end

      def get_ndx_action_indexes(inter_or_same,before_or_after)
        @ndx_action_indexes.get(inter_or_same,before_or_after)
      end
      def add_ndx_action_index(inter_or_same,before_or_after,action)
        @ndx_action_indexes.add(inter_or_same,before_or_after,action)
      end

      class InsertAtEnd < self
        def insert_action(template_content)
          pp [:in_insert_action]
          
          template_content.each_internode_stage do |internode_stage,stage_index|
            if action_match = find_earliest_match?(internode_stage,stage_index,:internode,:after)
              #if match here then need to put in stage earlier than matched one
              template_content.splice_in_action!(action_match,:before_internode_stage)
              return
            end
            if action_match = find_earliest_match?(internode_stage,stage_index,:samenode,:after)
              #if match here then need to put in this stage earlier than matched one
              template_content.splice_in_action!(action_match,:before_action_pos)
              return
            end
          end
           action_match = ActionMatch.new(@new_action)
           template_content.splice_in_action!(action_match,:end_last_internode_stage)
        end
      end
        
      def find_earliest_match?(internode_stage,stage_index,inter_or_same,before_or_after)
        ndx_action_indexes = get_ndx_action_indexes(inter_or_same,before_or_after)
        return nil if ndx_action_indexes.empty?()
        action_match = ActionMatch.new(@new_action)
        if internode_stage.find_earliest_match?(action_match,ndx_action_indexes)
          action_match.internode_stage_index = stage_index
          action_match
        end
      end

      InsertStrategies = {
        :insert_at_end => InsertAtEnd
      }
    end
  end
end;end;end
