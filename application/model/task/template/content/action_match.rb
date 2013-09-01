module DTK; class Task; class Template
  class Content
    class ActionMatch
      def initialize()
        @action = nil
        @internode_stage_index = nil
        @execution_block_index = nil
        @action_position = nil
      end
      attr_accessor :action,:internode_stage_index,:execution_block_index,:action_position
      def node_id()
        @action && @action.node_id()
      end
      def match_found?()
        !@action.nil?
      end
    end
  end
end;end;end

