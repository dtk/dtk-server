module DTK; class Task; class Template
  class Content
    class InsertActionInfo
      def self.create(new_action,action_list,temporal_constraints,insert_strategy=nil)
        insert_strategy_class(insert_strategy).new(new_action,action_list,temporal_constraints)
      end

      attr_reader :internode_before_actions,:internode_after_actions,:samenode_before_actions,:samenode_after_actions
     private
      def initialize(new_action,action_list,temporal_constraints,insert_strategy=nil)
        @new_action = new_action
        @new_action_node_id = new_action.node_id
        @internode_before_actions = Array.new
        @internode_after_actions = Array.new
        @samenode_before_actions = Array.new
        @samenode_after_actions = Array.new
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
              @samenode_after_actions <<  after_action
            else
              @internode_after_actions <<  after_action
            end
          elsif tc.after_action_index == new_action_index
            before_action = tc.before_action 
            if before_action.node_id == @new_action_node_id
              @samenode_before_actions <<  before_action
            else
              @internode_before_actions <<  before_action
            end
          end
        end
      end

      class InsertAtEnd < self
        def insert_action(template_content)
          pp [:in_insert_action,self]
          unless @internode_after_actions.empty? and @samenode_after_actions.empty?
            earliest_match = template_content.find_earliest_match(self)
            pp [:earliest_match,earliest_match]
          end
        end
      end

      InsertStrategies = {
        :insert_at_end => InsertAtEnd
      }
    end
  end
end;end;end
