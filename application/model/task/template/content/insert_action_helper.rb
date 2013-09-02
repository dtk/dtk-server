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
        #These are all index by node_id
        @internode_before_actions = Hash.new
        @internode_after_actions = Hash.new
        @samenode_before_actions = Hash.new
        @samenode_after_actions = Hash.new
        compute_before_after_relations!(temporal_constraints,action_list)
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
              add_indexed_action(@samenode_after_actions,after_action)
            else
              add_indexed_action(@internode_after_actions,after_action)
            end
          elsif tc.after_action_index == new_action_index
            before_action = tc.before_action 
            if before_action.node_id == @new_action_node_id
              add_indexed_action(@samenode_before_actions,before_action)
            else
              add_indexed_action(@internode_before_actions,before_action)
            end
          end
        end
      end

      def add_indexed_action(ndx_actions,action)
        ndx_actions.merge!(action.node_id => action)
      end

      class InsertAtEnd < self
        def insert_action(template_content)
          pp [:in_insert_action]
          
          template_content.each_internode_stage do |internode_stage,stage_index|
            if internode_match = find_earliest_match?(internode_stage,stage_index,@internode_after_actions)
              #if match here then need to put in stage earlier than matched one
              #TODO: stub
              pp [:internode_match_found,internode_match]
              return
            end
            if samenode_match = find_earliest_match?(internode_stage,stage_index,@samenode_after_actions)
              #if match here then need to put in stage earlier than matched one
              #TODO: stub
              pp [:smaenode_match_found,samenode_match]
              return
            end
          end
          pp [:no_match]
        end
      end
        
      def find_earliest_match?(internode_stage,stage_index,ndx_actions)
        return nil if ndx_actions.empty?()
        action_match = ActionMatch.new()
        if internode_stage.find_earliest_match?(action_match,ndx_actions)
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
