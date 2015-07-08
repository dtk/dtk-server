module DTK; class Task; class Template; class Stage
  class InterNode
    class Factory
      def initialize(action_list,temporal_constraints)
        @action_list = action_list
        @temporal_constraints = temporal_constraints
      end

      def create(stage_action_indexes,name=nil)
        # first break each state into unordered list per node
        ret = InterNode.new(name)
        stage_action_indexes.each do |i|
          action = @action_list.index(i)
          (ret[action.node_id] ||= IntraNode::Unordered.new()) << action
        end

        intra_node_proc = Stage::IntraNode::Processor.new(@temporal_constraints)
        ret.each_node_id{|node_id|ret[node_id] = intra_node_proc.process(ret[node_id])}
        ret
      end

      module StageName
        DefaultNameProc = lambda do |index,is_single_stage|
          ret = "configure_nodes"
          is_single_stage ? ret : (ret + "_stage_#{index}")
        end

        DefaultNodeGroupNameProc = lambda do |index,is_single_stage|
          ret = "config_node_group_components"
          is_single_stage ? ret : (ret + "_stage_#{index}")
        end
      end
    end
  end
end; end; end; end
