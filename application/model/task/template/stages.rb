module DTK; class Task 
  class Template
    class Stages < Array
      #TODO: make inner part indeexd by node; put in all temporal constraints; tehn for each stage use intra node to sert
      def self.create_internode_stages(temporal_constraints,action_list)
        inter_node_constraints = temporal_constraints.select{|r|r.inter_node?()}
        new(action_list).create_internode_stages!(inter_node_constraints)
      end

      def print_form()
        map{|stage|stage.map{|i|@action_list[i].print_form()}}
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
            stage = before_index_hash.ret_and_remove_actions_not_after_any!()
            if stage.empty?()
              #TODO: see if any other way there can be loops
              raise ErrorUsage.new("Loop detected in temporal orders")
            end
            self << stage
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
