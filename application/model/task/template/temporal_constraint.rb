module DTK; class Task 
  class Template
    class TemporalConstraint
      r8_nested_require('temporal_constraint','config_component')
      def initialize(before_action,after_action)
        @before_action = before_action
        @after_action = after_action
      end

      attr_reader :before_action,:after_action

      # subclasses override
      def intra_node?
        @before_action.node_id == @after_action.node_id
      end

      def inter_node?
        @before_action.node_id != @after_action.node_id
      end

      def before_action_index
        @before_action.index
      end

      def after_action_index
        @after_action.index
      end
    end
  end
end; end
