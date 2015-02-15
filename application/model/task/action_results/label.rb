module DTK; class Task
  module ActionResults
    module Label
      def self.label(action,top_task)
        if action[:node_group_member] 
          label_when_node_group(action,top_task)
        else
          label_when_node(action,top_task)
        end
      end

     private
      def self.label_when_node_group(action,top_task)
        ng_index = (action[:node]||{})[:index]
        bump_index = (ng_index.nil? or ng_index.to_s == '1')
        first_index = (bump_index ? top_task.bump_first_index_action_count!() : top_task.first_index_action_count())
        format_label(first_index,ng_index)
      end

      def self.label_when_node(action,top_task)
        format_label(top_task.bump_first_index_action_count!())
      end

      def self.format_label(first_index,second_index=nil)
        if second_index
          "#{first_index.to_s}#{LabelIndexDelimeter}#{second_index.to_s}"
        else
          first_index.to_s
        end
      end
      LabelIndexDelimeter = '.'
    end
  end
end; end
