module DTK; class Task 
  class Template
    class Stages < Array
      def self.create_internode_stages(temporal_constraints,action_list)
        inter_node_constraints = temporal_constraints.select{|r|r.inter_node?()}
        new(action_list).create_internode_stages!(inter_node_constraints)
      end

      def print_form()
        map{|stage|stage.print_form(@action_list)}
      end

      def create_internode_stages!(inter_node_constraints)
        return if @action_list.empty?
        unless empty?()
          raise Error.new("internode_stages has been created already")
        end
        before_index_hash = inter_node_constraints.create_before_index_hash(@action_list)
        done = false
        while not done do
          if before_index_hash.empty?
            done = true
          else
            stage_action_indexes = before_index_hash.ret_and_remove_actions_not_after_any!()
            if stage_action_indexes.empty?()
              #TODO: see if any other way there can be loops
              raise ErrorUsage.new("Loop detected in temporal orders")
            end
            self << Stage.create_with_unordered_intra_node_stages(stage_action_indexes,@action_list)
          end
        end
        self
      end

     private
      def initialize(action_list)
        @action_list = action_list
      end
    end
  end
end; end
