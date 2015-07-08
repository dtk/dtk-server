module DTK; class Task; class Template
  class Content
    class ActionMatch
      def initialize(insert_action=nil)
        @insert_action = insert_action
        # the rest of these attributes are about what matched
        @action = nil
        @in_multinode_stage = nil
        @internode_stage_index = nil
        @execution_block_index = nil
        @action_position = nil
      end
      attr_accessor :insert_action,:action,:internode_stage_index,:execution_block_index,:action_position,:in_multinode_stage
      def node_id
        @action && @action.node_id()
      end

      def match_found?
        !@action.nil?
      end
    end
  end
end;end;end
