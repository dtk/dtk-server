module DTK; class Task; class Template
  class Stage 
    class InterNode < Hash
      class Factory
        def initialize(action_list,temporal_constraints)
          @action_list = action_list
          @temporal_constraints = temporal_constraints
        end
        
        def create(stage_action_indexes)
          #first break each state into unordered list per node
          ret = InterNode.new()
          stage_action_indexes.each do |index|
            action = @action_list[index]
            (ret[action.node_id] ||= IntraNode::Unordered.new()) << action
          end
          
          #next break each unordered node into execution blocks
          ret.each_key{|node_id|ret[node_id] = ret[node_id].break_into_execution_blocks()}
          
          #order each execution block
          ret
        end
      end
      
      def serialization_form()
        ret = Array.new
        return ret if empty?
        each do |node_id,node_actions|
          ret << node_actions.map{|a|a.serialization_form()}
        end
        ret
      end
    end
  end
end; end; end

