module DTK; class Task 
  class Template
    class Stages < Array
      def initialize(temporal_constraints,action_list)
        @action_list = action_list
        super()
        return if action_list.empty?
        before_index_hash = temporal_constraints.create_before_index_hash(action_list)
        pp [:tsort_input,before_index_hash.tsort_form()]
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
      end

      def print_form()
        map{|stage|stage.map{|i|@action_list[i].print_form()}}
      end
    end
  end
end; end
