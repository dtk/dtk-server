module DTK; class Task; class Template
  class Stage 
    class InterNode < Hash
      #returns all actions generated
      def add_subtasks!(parent_task,internode_stage_index)
        ret = Array.new
        each_node_actions do |node_actions|
          if action = node_actions.add_subtask!(parent_task,internode_stage_index)
            ret << action
          end
        end
        ret
      end
      
      def serialization_form()
        ret = Array.new
        return ret if empty?
        each{|node_id,node_actions|ret << node_actions.serialization_form()}
        ret
      end
      
      def each_node_id(&block)
        each_key{|node_id|block.call(node_id)}
      end

      def each_node_actions(&block)
        each_value{|node_actions|block.call(node_actions)}
      end
      private :each_node_actions

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
          
          intra_node_proc = Stage::IntraNode::Processor.new(@temporal_constraints)
          ret.each_node_id{|node_id|ret[node_id] = intra_node_proc.process(ret[node_id])}
          ret
        end
      end
    end
  end
end; end; end

